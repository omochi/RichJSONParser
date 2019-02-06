import Foundation

public final class FastJSONParser {
    public enum Error : LocalizedError, CustomStringConvertible {
        case unexceptedEnd(SourceLocation)
        case invalidChar(UInt8, SourceLocation)
        
        public var errorDescription: String? {
            return description
        }
        
        public var description: String {
            switch self {
            case .unexceptedEnd(let loc):
                return "unexcepted end at \(loc)"
            case .invalidChar(let char, let loc):
                let char = String(format: "0x%c, 0x%02X", char, char)
                return "invalid char (\(char)) at \(loc)"
            }
        }
    }
    private enum State {
        case root(ParsedJSON?)
        case array(Array)
        case object(Object)
        
        final class Array {
            var array: [ParsedJSON]
            var location: SourceLocationLite
            
            init(array: [ParsedJSON],
                 location: SourceLocationLite)
            {
                self.array = array
                self.location = location
            }
        }
        
        final class Object {
            var object: JSONDictionary<ParsedJSON>
            var location: SourceLocationLite
            var key: String?
            
            init(object: JSONDictionary<ParsedJSON>,
                 location: SourceLocationLite)
            {
                self.object = object
                self.location = location
            }
        }
    }

    private let nsData: NSData
    private let data: UnsafeMutablePointer<UInt8>
    public let file: URL?
    private var location: SourceLocationLite
    
    private var stack: [State]
    private var state: State {
        get { return stack[stack.count - 1] }
        set { stack[stack.count - 1] = newValue }
    }
    
    private var byte: UInt8 {
        return data.advanced(by: location.offset).pointee
    }
    
    // it does not care about newline
    private func readByte() -> UInt8 {
        let b = byte
        location.addColumn(length: 1)
        return b
    }
    
    public init(file: URL) throws {
        let nsData = try NSMutableData(contentsOf: file, options: [])
        nsData.append(byte: 0)
        self.nsData = nsData
        self.data = nsData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        self.file = file
        self.stack = [State.root(nil)]
        self.location = SourceLocationLite()
    }
    
    public func parse() throws -> ParsedJSON {
        while true {
            if case .root(.some(let json)) = state
            {
                return json
            }
            
            let loc0 = location
            let b0 = byte
            
            switch b0 {
            case 0: throw unexceptedEndError(location: loc0)
            case .space, .tab:
                location.addColumn(length: 1)
            case .cr:
                processCR()
            case .lf:
                processLF()
            case .slash:
                try processComment(loc0)
            case .alSN:
                location.addColumn(length: 1)
                if readByte() == .alSU,
                    readByte() == .alSL,
                    readByte() == .alSL
                {
                    try emitValue(ParsedJSON(location: loc0, value: .null))
                } else {
                    throw invalidCharError(b0, location: loc0)
                }
            case .alST:
                location.addColumn(length: 1)
                if readByte() == .alSR,
                    readByte() == .alSU,
                    readByte() == .alSE
                {
                    try emitValue(ParsedJSON(location: loc0, value: .boolean(true)))
                } else {
                    throw invalidCharError(b0, location: loc0)
                }
            case .alSF:
                location.addColumn(length: 1)
                if readByte() == .alSA,
                readByte() == .alSL,
                readByte() == .alSS,
                readByte() == .alSE
                {
                    try emitValue(ParsedJSON(location: loc0, value: .boolean(false)))
                } else {
                    throw invalidCharError(b0, location: loc0)
                }
            case .doubleQuote:
                try processString(loc0)
            default:
                if b0 == .minus || b0.isDigit {
                    try processNumber(b0, loc0)
                }
            }
        }
    }
    
    private func mayConsumeComma() throws {
        while true {
            let loc0 = location
            let b0 = byte
            switch b0 {
            case 0:
                return
            case .space, .tab:
                location.addColumn(length: 1)
            case .cr:
                processCR()
            case .lf:
                processLF()
            case .slash:
                try processComment(loc0)
            case .comma:
                location.addColumn(length: 1)
                return
            default:
                return
            }
        }
    }
    
    private func processCR() {
        location.addColumn(length: 1)
        let b1 = byte
        switch b1 {
        case .lf:
            processLF()
        default:
            break
        }
    }
    
    private func processLF() {
        location.addLine(newLineLength: 1)
    }
    
    private func processComment(_ loc0: SourceLocationLite) throws {
        location.addColumn(length: 1)
        let b1 = byte
        switch b1 {
        case .slash:
            location.addColumn(length: 1)
            while true {
                let b2 = byte
                switch b2 {
                case 0: return
                case .cr, .lf: return
                default:
                    location.addColumn(length: 1)
                }
            }
        case .star:
            location.addColumn(length: 1)
            while true {
                let b2 = byte
                switch b2 {
                case 0: return
                case .cr:
                    processCR()
                case .lf:
                    processLF()
                case .star:
                    location.addColumn(length: 1)
                    let b3 = byte
                    switch b3 {
                    case .slash:
                        location.addColumn(length: 1)
                        return
                    default:
                        break
                    }
                default:
                    location.addColumn(length: 1)
                }
            }
        default:
            throw invalidCharError(.slash, location: loc0)
        }
    }
    
    private func processNumber(_ b0: UInt8, _ loc0: SourceLocationLite) throws {
        let b1: UInt8
        if b0 == .minus {
            location.addColumn(length: 1)
            b1 = byte
        } else {
            b1 = b0
        }
        
        if b1 == .num0 {
            location.addColumn(length: 1)
        } else if b1.isDigit1To9 {
            location.addColumn(length: 1)
            
            while true {
                let b2 = byte
                if b2.isDigit {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        } else {
            throw invalidCharError(b0, location: loc0)
        }
        
        let b2 = byte
        if b2 == .dot {
            location.addColumn(length: 1)
            
            while true {
                let b3 = byte
                if b3.isDigit {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        }
        
        let b3 = byte
        if b3 == .alSE || b3 == .alLE {
            location.addColumn(length: 1)
            
            let b4 = byte
            if b4 == .plus || b4 == .minus {
                location.addColumn(length: 1)
            }
            
            while true {
                let b5 = byte
                if b5.isDigit {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        }
        
        let str = makeString(start: loc0, end: location)
        let json = ParsedJSON(location: loc0, value: .number(str))
        try emitValue(json)
    }
    
    private func processString(_ loc0: SourceLocationLite) throws {
//        if try tryProcessFastString(loc0) {
//            return
//        }
        
        location.addColumn(length: 1)
        
        let result = NSMutableData()
        
        while true {
            let loc1 = location
            let b1 = byte
            if b1 == .doubleQuote {
                location.addColumn(length: 1)
                break
            } else if b1 == .backSlash {
                location.addColumn(length: 1)
                result.append(byte: b1)
                
                let b2 = byte
                switch b2 {
                case .doubleQuote:
                    location.addColumn(length: 1)
                    result.append(byte: .doubleQuote)
                case .backSlash:
                    location.addColumn(length: 1)
                    result.append(byte: .backSlash)
                case .slash:
                    location.addColumn(length: 1)
                    result.append(byte: .slash)
                case .alSB:
                    location.addColumn(length: 1)
                    result.append(byte: .backSpace)
                case .alSF:
                    location.addColumn(length: 1)
                    result.append(byte: .backSpace)
                case .alSN:
                    location.addColumn(length: 1)
                    result.append(byte: .lf)
                case .alSR:
                    location.addColumn(length: 1)
                    result.append(byte: .cr)
                case .alST:
                    location.addColumn(length: 1)
                    result.append(byte: .tab)
                case .alSU:
                    location.addColumn(length: 1)
                    
                    guard var code = decodeEscapedUnicode1() else {
                        throw invalidCharError(b1, location: loc1)
                    }
                    
                    if code.isLowSurrogate {
                        throw invalidCharError(b1, location: loc1)
                    }
                    
                    if code.isHighSurrogate {
                        guard let code2 = decodeEscapedUnicode(),
                            code2.isLowSurrogate else
                        {
                            throw invalidCharError(b1, location: loc1)
                        }
                        
                        code = UInt32.combineSurrogates(high: code, low: code2)
                    }
                    
                    guard let uni = Unicode.Scalar(code) else {
                        throw invalidCharError(b1, location: loc1)
                    }
                    for x in String(String.UnicodeScalarView([uni])).utf8 {
                        result.append(byte: x)
                    }
                default:
                    throw invalidCharError(b1, location: loc1)
                }
            } else if b1.isPrintable {
                location.addColumn(length: 1)
                result.append(byte: b1)
            } else if b1 == 0 {
                throw unexceptedEndError(location: loc1)
            } else if validateUTF8MultiBytes(b1, loc1) {
                let len = location.offset - loc1.offset
                result.append(data.advanced(by: loc1.offset), length: len)
            } else {
                throw invalidCharError(b1, location: loc0)
            }
        }
        
        result.append(byte: 0)
        
        let str = String(cString: result.bytes.assumingMemoryBound(to: UInt8.self))
        let json = ParsedJSON(location: loc0, value: .string(str))
        try emitValue(json)
    }
    
    private func decodeEscapedUnicode() -> UInt32? {
        guard readByte() == .backSlash,
            readByte() == .alSU else { return nil }
        return decodeEscapedUnicode1()
    }
    
    private func decodeEscapedUnicode1() -> UInt32? {
        var code: UInt32 = 0
        for _ in 0..<4 {
            let b0 = byte
            guard let v = b0.hexValue else { return nil }
            location.addColumn(length: 1)
            code = (code << 8) + UInt32(v)
        }
        return code
    }
    
    private func tryProcessFastString(_ loc0: SourceLocationLite) throws -> Bool {
        location.addColumn(length: 1)
        
        let loc1 = location
        var loc2 = loc1
        while true {
            let b1 = byte
            if b1 == .doubleQuote {
                loc2 = location
                location.addColumn(length: 1)
            } else if b1 == .backSlash {
                return false
            } else if b1.isPrintable {
                location.addColumn(length: 1)
            } else {
                return false
            }
        }
        
        let str = makeString(start: loc1, end: loc2)
        let json = ParsedJSON(location: loc0, value: .string(str))
        try emitValue(json)
        return true
    }
    
    private func validateUTF8MultiBytes(_ b0: UInt8, _ loc0: SourceLocationLite) -> Bool {
        if 0xC2 <= b0 && b0 <= 0xDF {
            location.addColumn(length: 1)
            let b1 = byte
            guard 0x80 <= b1 && b1 <= 0xBF else {
                return false
            }
            location.addColumn(length: 1)
            return true
        } else if 0xE0 <= b0 && b0 <= 0xEF {
            location.addColumn(length: 1)
            
            var code = UInt32(b0) & 0x0F

            let b1 = byte
            guard 0x80 <= b1 && b1 <= 0xBF else { return false }
            location.addColumn(length: 1)
            code = (code << 6) + UInt32(b1) & 0x3F
            
            let b2 = byte
            guard 0x80 <= b2 && b2 <= 0xBF else { return false }
            location.addColumn(length: 1)
            code = (code << 6) + UInt32(b2) & 0x3F

            guard 0x0800 <= code && code <= 0xFFFF else { return false }
            if 0xD800 <= code && code <= 0xDFFF { return false }
            return true
        } else if 0xF0 <= b0 && b0 <= 0xF4 {
            location.addColumn(length: 1)
            
            var code = UInt32(b0) & 0x07
            
            let b1 = byte
            guard 0x80 <= b1 && b1 <= 0xBF else { return false }
            location.addColumn(length: 1)
            code = (code << 6) + UInt32(b1) & 0x3F
            
            let b2 = byte
            guard 0x80 <= b2 && b2 <= 0xBF else { return false }
            location.addColumn(length: 1)
            code = (code << 6) + UInt32(b2) & 0x3F
            
            let b3 = byte
            guard 0x80 <= b3 && b3 <= 0xBF else { return false }
            location.addColumn(length: 1)
            code = (code << 6) + UInt32(b3) & 0x3F
            
            guard 0x01_0000 <= code && code <= 0x1F_FFFF else { return false }
            return true
        } else {
            return false
        }
    }
    
    private func makeString(start: SourceLocationLite,
                            end: SourceLocationLite)
        -> String
    {
        let start = data.advanced(by: start.offset)
        let end = data.advanced(by: end.offset)
        
        let be = end.pointee
        end.pointee = 0
        let str = String(cString: start)
        end.pointee = be
        return str
    }

    private func emitValue(_ json: ParsedJSON) throws {
        switch state {
        case .root:
            state = .root(json)
        case .array(let state):
            state.array.append(json)
            try mayConsumeComma()
        case .object(let state):
            let key = state.key!
            state.object[key] = json
            try mayConsumeComma()
        }
    }
    
    private func addArrayItem(state: State.Array,
                              value: ParsedJSON)
    {
        state.array.append(value)
    }
    
    private func addObjectItem(state: State.Object,
                               value: ParsedJSON)
    {
        let key = state.key!
        state.object[key] = value
    }
    
    private func unexceptedEndError(location: SourceLocationLite) -> Error {
        return Error.unexceptedEnd(location.with(file: file))
    }
    
    private func invalidCharError(_ char: UInt8, location: SourceLocationLite) -> Error {
        return Error.invalidChar(char, location.with(file: file))
    }
}
