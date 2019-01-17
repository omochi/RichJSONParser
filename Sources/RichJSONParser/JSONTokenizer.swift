import Foundation

internal extension Unicode.Scalar {
    static let cr = Unicode.Scalar(0x0D)!
    static let lf = Unicode.Scalar(0x0A)!
    static let tab = Unicode.Scalar(0x09)!
    static let space = Unicode.Scalar(0x20)!
    
    static let doubleQuote = Unicode.Scalar(0x22)!
    
    static let plus = Unicode.Scalar(0x2B)!
    static let minus = Unicode.Scalar(0x2D)!
    static let star = Unicode.Scalar(0x2A)!
    static let slash = Unicode.Scalar(0x2F)!
    static let comma = Unicode.Scalar(0x2C)!
    static let dot = Unicode.Scalar(0x2E)!
    static let colon = Unicode.Scalar(0x3A)!
    static let backSlash = Unicode.Scalar(0x5C)!
    static let leftBracket = Unicode.Scalar(0x5B)!
    static let rightBracket = Unicode.Scalar(0x5D)!
    static let leftBrace = Unicode.Scalar(0x7B)!
    static let rightBrace = Unicode.Scalar(0x7D)!
    
    static let num0 = Unicode.Scalar(0x30)!
    static let num1 = Unicode.Scalar(0x31)!
    static let num9 = Unicode.Scalar(0x39)!

    static let alphaSA = Unicode.Scalar(0x61)!
    static let alphaSB = Unicode.Scalar(0x62)!
    static let alphaSE = Unicode.Scalar(0x65)!
    static let alphaSF = Unicode.Scalar(0x66)!
    static let alphaSN = Unicode.Scalar(0x6e)!
    static let alphaSR = Unicode.Scalar(0x72)!
    static let alphaST = Unicode.Scalar(0x74)!
    static let alphaSU = Unicode.Scalar(0x75)!
    static let alphaSZ = Unicode.Scalar(0x7A)!
    
    static let alphaLA = Unicode.Scalar(0x41)!
    static let alphaLE = Unicode.Scalar(0x45)!
    static let alphaLF = Unicode.Scalar(0x46)!
    static let alphaLZ = Unicode.Scalar(0x5A)!
    
    func isNum0to9() -> Bool {
        return .num0 <= self && self <= .num9
    }
    
    func isNum1To9() -> Bool {
        return .num1 <= self && self <= .num9
    }
    
    func isHex() -> Bool {
        return isNum0to9() ||
        .alphaSA <= self && self <= .alphaSF ||
        .alphaLA <= self && self <= .alphaLF
    }
    
    func isAlpha() -> Bool {
        return .alphaSA <= self && self <= .alphaSZ ||
            .alphaLA <= self && self <= .alphaLZ
    }
    
    func isControlCode() -> Bool {
        let x = self.value
        
        return 0x00 <= x && x <= 0x1F ||
            x == 0x7F ||
            0x80 <= x && x <= 0x9F
    }
}

public class JSONTokenizer {
    public enum Error : Swift.Error, CustomStringConvertible {
        case invalidChar(SourceLocation, Unicode.Scalar)
        case unexceptedEnd(SourceLocation)
        case utf8Error(SourceLocation, UTF8Decoder.Error)
        
        public var description: String {
            switch self {
            case .invalidChar(let loc, let ch):
                let chHex = String(format: "%04X", ch.value)
                return "invalid character (\(ch), U+\(chHex)) at \(loc)"
            case .unexceptedEnd(let loc):
                return "unexpected end of data at \(loc)"
            case .utf8Error(let loc, let e):
                return "utf8 decode failed at \(loc), \(e)"
            }
        }
    }
    
    private let data: Data
    public var location: SourceLocation
    
    public init(data: Data) {
        self.data = data
        self.location = SourceLocation(offset: 0, line: 1, columnInByte: 1)
    }
    
    public func read() throws -> JSONToken {
        let start = location
        
        guard let c0 = try char(at: location) else {
            return buildToken(start: start, kind: .end)
        }
        
        let c0c = c0.codePoint
        
        if c0c == .cr {
            if let c1 = try char(at: location + 1),
                c1.codePoint == .lf
            {
                location.addLine(newLineLength: 2)
                return buildToken(start: start, kind: .newLine)
            } else {
                location.addLine(newLineLength: 1)
                return buildToken(start: start, kind: .newLine)
            }
        } else if c0c == .lf {
            location.addLine(newLineLength: 1)
            return buildToken(start: start, kind: .newLine)
        } else if c0c == .tab || c0c == .space {
            location.addColumn(length: 1)
            while true {
                guard let c1 = try char(at: location) else {
                    break
                }
                if c1.codePoint == .tab || c1.codePoint == .space {
                    location.addColumn(length: 1)
                    continue
                }
                break
            }
            return buildToken(start: start, kind: .whiteSpace)
        } else if c0c == .slash {
            if let c1 = try char(at: location + 1) {
                if c1.codePoint == .slash {
                    return try readLineComment()
                } else if c1.codePoint == .star {
                    return try readBlockComment()
                }
            }
            
            throw Error.invalidChar(location, c0c)
        } else if c0c == .minus || c0c.isNum0to9() {
            return try readNumber()
        } else if c0c == .doubleQuote {
            return try readString()
        } else if c0c.isAlpha() {
            return try readKeyword()
        } else if c0c == .leftBracket {
            return buildToken(start: start, kind: .leftBracket)
        } else if c0c == .rightBracket {
            return buildToken(start: start, kind: .rightBracket)
        } else if c0c == .leftBrace {
            return buildToken(start: start, kind: .leftBrace)
        } else if c0c == .rightBrace {
            return buildToken(start: start, kind: .rightBrace)
        } else if c0c == .comma {
            return buildToken(start: start, kind: .comma)
        } else if c0c == .colon {
             return buildToken(start: start, kind: .colon)
        } else {
            throw Error.invalidChar(location, c0c)
        }
    }
    
    public func readLineComment() throws -> JSONToken {
        let start = location
        
        guard let ac0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac0.codePoint == .slash else {
            throw Error.invalidChar(location, ac0.codePoint)
        }
        location.addColumn(length: 1)
        
        guard let ac1 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac1.codePoint == .slash else {
            throw Error.invalidChar(location, ac1.codePoint)
        }
        location.addColumn(length: 1)
        
        while true {
            guard let c0 = try char(at: location) else {
                return buildToken(start: start, kind: .lineComment)
            }
            if c0.codePoint == .cr || c0.codePoint == .lf {
                return buildToken(start: start, kind: .lineComment)
            } else {
                location.addColumn(length: c0.length)
            }
        }
    }
    
    public func readBlockComment() throws -> JSONToken {
        let start = location
        
        guard let ac0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac0.codePoint == .slash else {
            throw Error.invalidChar(location, ac0.codePoint)
        }
        location.addColumn(length: 1)
        
        guard let ac1 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac1.codePoint == .star else {
            throw Error.invalidChar(location, ac1.codePoint)
        }
        location.addColumn(length: 1)
        
        while true {
            guard let c0 = try char(at: location) else {
                return buildToken(start: start, kind: .blockComment)
            }
            if c0.codePoint == .cr {
                if let c1 = try char(at: location + 1),
                    c1.codePoint == .lf
                {
                    location.addLine(newLineLength: 2)
                } else {
                    location.addLine(newLineLength: 1)
                }
            } else if c0.codePoint == .lf {
                location.addLine(newLineLength: 1)
            } else if c0.codePoint == .star {
                guard let c1 = try char(at: location + 1) else {
                    location.addColumn(length: 1)
                    return buildToken(start: start, kind: .blockComment)
                }
                if c1.codePoint == .slash {
                    location.addColumn(length: 2)
                    return buildToken(start: start, kind: .blockComment)
                }
                location.addColumn(length: 1)
            } else {
                location.addColumn(length: c0.length)
            }
        }
    }
    
    public func readNumber() throws -> JSONToken {
        let start = location
        
        guard let c0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        
        if c0.codePoint == .minus {
            location.addColumn(length: 1)
        }
        
        guard let c1 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        
        if c1.codePoint == .num0 {
            location.addColumn(length: 1)
        } else if c1.codePoint.isNum1To9() {
            location.addColumn(length: 1)
            
            while true {
                if let c2 = try char(at: location),
                    c2.codePoint.isNum0to9()
                {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        } else {
            throw Error.invalidChar(location, c1.codePoint)
        }
        
        guard let c2 = try char(at: location) else {
            return buildToken(start: start, kind: .number)
        }
        
        if c2.codePoint == .dot {
            location.addColumn(length: 1)
            
            while true {
                if let c3 = try char(at: location),
                    c3.codePoint.isNum0to9()
                {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        }
        
        guard let c3 = try char(at: location) else {
            return buildToken(start: start, kind: .number)
        }
        
        if c3.codePoint == .alphaSE || c3.codePoint == .alphaLE {
            location.addColumn(length: 1)
            
            if let c4 = try char(at: location),
                c4.codePoint == .plus || c4.codePoint == .minus
            {
                location.addColumn(length: 1)
            }
            
            while true {
                if let c5 = try char(at: location),
                    c5.codePoint.isNum0to9()
                {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        }
        
        return buildToken(start: start, kind: .number)
    }
    
    private func readString() throws -> JSONToken {
        let start = location
        
        guard let c0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard c0.codePoint == .doubleQuote else {
            throw Error.invalidChar(location, c0.codePoint)
        }
        location.addColumn(length: 1)
        
        while true {
            guard let c1 = try char(at: location) else {
                throw Error.unexceptedEnd(location)
            }
            
            if c1.codePoint == .doubleQuote {
                location.addColumn(length: 1)
                return buildToken(start: start, kind: .string)
            } else if c1.codePoint == .backSlash {
                guard let c2 = try char(at: location) else {
                    throw Error.unexceptedEnd(location)
                }
                let c2c = c2.codePoint
                if c2c == .doubleQuote ||
                    c2c == .backSlash ||
                    c2c == .slash ||
                    c2c == .alphaSB ||
                    c2c == .alphaSF ||
                    c2c == .alphaSN ||
                    c2c == .alphaSR ||
                    c2c == .alphaST
                {
                    location.addColumn(length: 1)
                } else if c2c == .alphaSU {
                    location.addColumn(length: 1)
                    
                    for _ in 0..<4 {
                        guard let c3 = try char(at: location) else {
                            throw Error.unexceptedEnd(location)
                        }
                        guard c3.codePoint.isHex() else {
                            throw Error.invalidChar(location, c3.codePoint)
                        }
                        location.addColumn(length: 1)
                    }
                } else {
                    throw Error.invalidChar(location, c2c)
                }
            } else if c1.codePoint.isControlCode() {
                throw Error.invalidChar(location, c1.codePoint)
            } else {
                location.addColumn(length: c1.length)
            }
        }
    }
    
    private func readKeyword() throws -> JSONToken {
        let start = location
        
        guard let c0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard c0.codePoint.isAlpha() else {
            throw Error.invalidChar(location, c0.codePoint)
        }
        
        while true {
            if let c1 = try char(at: location),
                c1.codePoint.isAlpha()
            {
                location.addColumn(length: 1)
            } else {
                return buildToken(start: start, kind: .keyword)
            }
        }
    }
    
    private func buildToken(start: SourceLocation,
                            kind: JSONToken.Kind) -> JSONToken
    {
        return JSONToken(location: start,
                         length: location.offset - start.offset,
                         kind: kind)
    }
    
    private func char(at location: SourceLocation) throws -> DecodedUnicodeChar? {
        do {
            guard let ch = try UTF8Decoder.readUTF8(at: location.offset, from: data) else {
                return nil
            }
            return ch
        } catch let error as UTF8Decoder.Error {
            throw Error.utf8Error(location, error)
        }
    }
}
