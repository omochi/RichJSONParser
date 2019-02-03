import Foundation

public class JSONTokenizer {
    public enum Error : LocalizedError, CustomStringConvertible {
        case invalidCharacter(SourceLocation, Unicode.Scalar)
        case unexceptedEnd(SourceLocation)
        case utf8DecodeError(SourceLocation, Swift.Error?)
        case stringUnescapeError(SourceLocation, Swift.Error)
        
        public var errorDescription: String? { return description }
        
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
    
    private let _data: NSData
    private let data: UnsafePointer<UInt8>
    public var location: SourceLocation
    
    private var dataSize: Int {
        return _data.length
    }
    
    public init(data: Data, file: URL? = nil) {
        self._data = NSData(data: data) // drop subData
        self.location = SourceLocation(offset: 0,
                                       line: 1,
                                       columnInByte: 1,
                                       file: file)
        
        self.data = _data.bytes.assumingMemoryBound(to: UInt8.self)
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
            location.addColumn(length: 1)
            return buildToken(start: start, kind: .leftBracket)
        } else if c0c == .rightBracket {
            location.addColumn(length: 1)
            return buildToken(start: start, kind: .rightBracket)
        } else if c0c == .leftBrace {
            location.addColumn(length: 1)
            return buildToken(start: start, kind: .leftBrace)
        } else if c0c == .rightBrace {
            location.addColumn(length: 1)
            return buildToken(start: start, kind: .rightBrace)
        } else if c0c == .comma {
            location.addColumn(length: 1)
            return buildToken(start: start, kind: .comma)
        } else if c0c == .colon {
            location.addColumn(length: 1)
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
        
        func unescape() throws -> String {
            let start = location
            
            do {
                let result = try JSONStringEscape
                    .unescapingDecode(data: data,
                                      start: start.offset,
                                      size: dataSize)
                location.addColumn(length: result.consumedSize)
                return result.string
            } catch {
                throw Error.stringUnescapeError(start, error)
            }
        }

        let string = try unescape()
        
        guard let c1 = try char(at: location) else {
            throw Error.unexceptedEnd(location)
        }
        guard c1.codePoint == .doubleQuote else {
            throw Error.invalidCharacter(location, c1.codePoint)
        }
        location.addColumn(length: 1)
        
        return buildToken(start: start,
                          kind: .string,
                          string: string)
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
                let string = try decodeUTF8(start: start, end: location)
                return buildToken(start: start,
                                  kind: .keyword,
                                  string: string)
            }
        }
    }
    
    private func buildNumberToken(start: SourceLocation) throws -> JSONToken {
        let string = try decodeUTF8(start: start, end: location)
        return buildToken(start: start, kind: .number, string: string)
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

    private func decodeUTF8(start: SourceLocation,
                            end: SourceLocation)
        throws -> String
    {
        let offset = start.offset
        let length = end.offset - offset
        
        guard offset + length <= dataSize else {
            fatalError("out of range")
        }
        
        let data = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: self.data.advanced(by: offset)),
                        count: length,
                        deallocator: .none)
        
        guard let str = String(data: data, encoding: .utf8) else {
            throw Error.utf8DecodeError(start, nil)
        }
        return str
    }
    
    private func char(at location: SourceLocation) throws -> DecodedUnicodeChar? {
        do {
            return try UTF8Decoder.decodeUTF8(at: location.offset,
                                              from: data,
                                              size: dataSize)
        } catch {
            throw Error.utf8DecodeError(location, error)
        }
    }
    
}
