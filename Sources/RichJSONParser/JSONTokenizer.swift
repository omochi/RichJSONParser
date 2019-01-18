import Foundation

public class JSONTokenizer {
    public enum Error : Swift.Error, CustomStringConvertible {
        case invalidCharacter(SourceLocation, Unicode.Scalar)
        case unexceptedEnd(SourceLocation)
        case utf8DecodeError(SourceLocation, Swift.Error?)
        case stringUnescapeError(SourceLocation, Swift.Error)
        
        public var description: String {
            switch self {
            case .invalidCharacter(let loc, let ch):
                return "invalid character (\(ch.debugDescription)) at \(loc)"
            case .unexceptedEnd(let loc):
                return "unexpected end of data at \(loc)"
            case .utf8DecodeError(let loc, let e):
                var d = "utf8 decode failed at \(loc)"
                if let e = e {
                    d += ", \(e)"
                }
                return d
            case .stringUnescapeError(let loc, let e):
                return "string unescape failed at \(loc), \(e)"
            }
        }
    }
    
    private let data: Data
    public var location: SourceLocation
    
    public init(data: Data) {
        self.data = Data(data) // drop subData
        self.location = SourceLocation(offset: 0, line: 1, columnInByte: 1)
    }
    
    public func data(of token: JSONToken) -> Data {
        let start = token.location.offset
        let end = start + token.length
        return self.data[start..<end]
    }
    
    public func read() throws -> JSONToken {
        while true {
            let token = try readRaw()
            switch token.kind {
            case .newLine,
                 .whiteSpace,
                 .lineComment,
                 .blockComment:
                continue
            default:
                return token
            }
        }
    }
    
    public func readRaw() throws -> JSONToken {
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
            
            throw Error.invalidCharacter(location, c0c)
        } else if c0c == .minus || c0c.isDigit {
            return try readNumber()
        } else if c0c == .doubleQuote {
            return try readString()
        } else if c0c.isAlpha {
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
            throw Error.invalidCharacter(location, c0c)
        }
    }
    
    public func readLineComment() throws -> JSONToken {
        let start = location
        
        guard let ac0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac0.codePoint == .slash else {
            throw Error.invalidCharacter(location, ac0.codePoint)
        }
        location.addColumn(length: 1)
        
        guard let ac1 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac1.codePoint == .slash else {
            throw Error.invalidCharacter(location, ac1.codePoint)
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
            throw Error.invalidCharacter(location, ac0.codePoint)
        }
        location.addColumn(length: 1)
        
        guard let ac1 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard ac1.codePoint == .star else {
            throw Error.invalidCharacter(location, ac1.codePoint)
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
        } else if c1.codePoint.isDigit1To9 {
            location.addColumn(length: 1)
            
            while true {
                if let c2 = try char(at: location),
                    c2.codePoint.isDigit
                {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        } else {
            throw Error.invalidCharacter(location, c1.codePoint)
        }
        
        guard let c2 = try char(at: location) else {
            return try buildNumberToken(start: start)
        }
        
        if c2.codePoint == .dot {
            location.addColumn(length: 1)
            
            while true {
                if let c3 = try char(at: location),
                    c3.codePoint.isDigit
                {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        }
        
        guard let c3 = try char(at: location) else {
            return try buildNumberToken(start: start)
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
                    c5.codePoint.isDigit
                {
                    location.addColumn(length: 1)
                } else {
                    break
                }
            }
        }
        
        return try buildNumberToken(start: start)
    }
    
    private func readString() throws -> JSONToken {
        let start = location
        
        guard let c0 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard c0.codePoint == .doubleQuote else {
            throw Error.invalidCharacter(location, c0.codePoint)
        }
        location.addColumn(length: 1)
        
        while true {
            guard let c1 = try char(at: location) else {
                throw Error.unexceptedEnd(location)
            }
            
            if c1.codePoint == .doubleQuote {
                location.addColumn(length: 1)
                
                return try buildStringToken(start: start)
            } else if c1.codePoint == .backSlash {
                location.addColumn(length: 1)
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
                        guard c3.codePoint.isHex else {
                            throw Error.invalidCharacter(location, c3.codePoint)
                        }
                        location.addColumn(length: 1)
                    }
                } else {
                    throw Error.invalidCharacter(location, c2c)
                }
            } else if c1.codePoint.isControlCode {
                throw Error.invalidCharacter(location, c1.codePoint)
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
        guard c0.codePoint.isAlpha else {
            throw Error.invalidCharacter(location, c0.codePoint)
        }
        
        while true {
            if let c1 = try char(at: location),
                c1.codePoint.isAlpha
            {
                location.addColumn(length: 1)
            } else {
                let data = currentTokenData(start: start)
                let string = try decodeUTF8(data: data, location: start)
                return buildToken(start: start,
                                  kind: .keyword,
                                  string: string)
            }
        }
    }
    
    private func buildNumberToken(start: SourceLocation) throws -> JSONToken {
        let data = currentTokenData(start: start)
        let string = try decodeUTF8(data: data, location: start)
        return buildToken(start: start, kind: .number, string: string)
    }
    
    private func buildStringToken(start: SourceLocation) throws -> JSONToken {
        let dataE = currentTokenData(start: start)
        let dataU = try unescapeString(data: dataE, location: start)
        let string = try decodeUTF8(data: dataU, location: start)
        return buildToken(start: start, kind: .string, string: string)
    }
    
    private func buildToken(start: SourceLocation,
                            kind: JSONToken.Kind,
                            string: String? = nil) -> JSONToken
    {
        return JSONToken(location: start,
                         length: location.offset - start.offset,
                         kind: kind,
                         string: string)
    }
    
    private func currentTokenData(start: SourceLocation) -> Data {
        let s = start.offset
        let e = location.offset
        return data[s..<e]
    }
    
    private func unescapeString(data: Data, location: SourceLocation) throws -> Data {
        do {
            return try JSONStringEscape.unescape(data: data)
        } catch {
            throw Error.stringUnescapeError(location, error)
        }
    }
    
    private func decodeUTF8(data: Data, location: SourceLocation) throws -> String {
        guard let str = String(data: data, encoding: .utf8) else {
            throw Error.utf8DecodeError(location, nil)
        }
        return str
    }
    
    private func char(at location: SourceLocation) throws -> DecodedUnicodeChar? {
        do {
            return try UTF8Decoder.decodeUTF8(at: location.offset, from: data)
        } catch {
            throw Error.utf8DecodeError(location, error)
        }
    }
    
}
