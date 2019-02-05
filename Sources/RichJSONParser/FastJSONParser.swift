import Foundation

public final class FastJSONParser {
    public enum Error : LocalizedError, CustomStringConvertible {
        case unexceptedEnd(SourceLocation)
        
        public var errorDescription: String? {
            return description
        }
        
        public var description: String {
            switch self {
            case .unexceptedEnd(let loc):
                return "unexcepted end at \(loc)"
            }
        }
    }
    private enum State {
        case start
        case complete(ParsedJSON)
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
        let b = self.byte
        location.addColumn(length: 1)
        return b
    }
    
    public init(file: URL) throws {
        let nsData = try NSMutableData(contentsOf: file, options: [])
        nsData.append(byte: 0)
        self.nsData = nsData
        self.data = nsData.mutableBytes.assumingMemoryBound(to: UInt8.self)
        self.file = file
        self.stack = [State.start]
        self.location = SourceLocationLite()
    }
    
    public func parse() throws -> ParsedJSON {
        while true {
            let b0 = self.byte
            
            switch b0 {
            case 0: throw unexceptedEndError(location: location)
            case .space, .tab:
                location.addColumn(length: 1)
            case .cr:
                location.addColumn(length: 1)
                let b1 = self.byte
                if b1 == .lf {
                    location.addLine(newLineLength: 1)
                }
            case .lf:
                location.addLine(newLineLength: 1)
            case .alphaSN:
                location.addColumn(length: 1)
                if readByte() == .alphaSU,
                    readByte() == .alphaSL,
                    readByte() == .alphaSL
                {
                    try emitValue(ParsedJSON(location: location, value: .null))
                }
            }
        }
    }
    
    private func mayConsumeComma() throws {
        while true {
            let b0 = self.byte
            
            switch b0 {
            case 0:
                return
            case .space, .tab:
                location.addColumn(length: 1)
            case .cr:
                location.addColumn(length: 1)
                let b1 = self.byte
                if b1 == .lf {
                    location.addLine(newLineLength: 1)
                }
            case .lf:
                location.addLine(newLineLength: 1)
                // TODO: comment
            case .comma:
                location.addColumn(length: 1)
                return
            default:
                return
            }
        }
    }
    
    private func emitValue(_ value: ParsedJSON) throws {
        if stack.count == 1 {
            self.state = .complete(value)
            return
        }
        
        stack.removeLast()
        
        switch state {
        case .array(let state):
            try addArrayItem(state: state, value: value)
        case .object(let state):
            try addObjectItem(state: state, value: value)
        default: fatalError("invalid state")
        }
    }
    
    private func addArrayItem(state: State.Array,
                              value: ParsedJSON) throws
    {
        state.array.append(value)
        
        try mayConsumeComma()
    }
    
    private func addObjectItem(state: State.Object,
                               value: ParsedJSON) throws
    {
        let key = state.key!
        
        state.object[key] = value
        
        try mayConsumeComma()
    }
    
    private func unexceptedEndError(location: SourceLocationLite) -> Error {
        return Error.unexceptedEnd(location.with(file: file))
    }
}
