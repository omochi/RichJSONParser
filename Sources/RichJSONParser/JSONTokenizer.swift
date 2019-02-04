import Foundation

public class JSONTokenizer {
    public enum Error : LocalizedError, CustomStringConvertible {
        case invalidCharacter(SourceLocation, Unicode.Scalar)
        case unexceptedEnd(SourceLocation)
        case stringUnescapeError(SourceLocation, Swift.Error)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .invalidCharacter(let loc, let ch):
                return "invalid character (\(ch.debugDescription)) at \(loc)"
            case .unexceptedEnd(let loc):
                return "unexpected end of data at \(loc)"
            case .stringUnescapeError(let loc, let e):
                return "string unescape failed at \(loc), \(e)"
            }
        }
    }
    
    private let reader: UTF8Reader
    private let unescapingBuffer: StaticBuffer
    
    public init(data: Data, file: URL? = nil) throws {
        self.reader = try UTF8Reader(data: data, file: file)
        self.unescapingBuffer = StaticBuffer(capacity: data.count)
    }
    
    public var file: URL? {
        return reader.file
    }
    
    public var location: SourceLocationLite {
        return reader.location
    }
    
    public func seek(to location: SourceLocationLite) throws {
        try reader.seek(to: location)
    }
    
    private var char: Unicode.Scalar? {
        return reader.char
    }
    
    @discardableResult
    private func readChar() throws -> Unicode.Scalar? {
        return try reader.read()
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
        
        let c0Loc = location
        guard let c0 = char else {
            return buildToken(start: start, kind: .end)
        }
        
        if c0 == .cr {
            try readChar()
            if let c1 = char,
                c1 == .lf
            {
                try readChar()
                return buildToken(start: start, kind: .newLine)
            } else {
                return buildToken(start: start, kind: .newLine)
            }
        } else if c0 == .lf {
            try readChar()
            return buildToken(start: start, kind: .newLine)
        } else if c0 == .tab || c0 == .space {
            try readChar()
            while true {
                guard let c1 = char else {
                    break
                }
                if c1 == .tab || c1 == .space {
                    try readChar()
                    continue
                }
                break
            }
            return buildToken(start: start, kind: .whiteSpace)
        } else if c0 == .slash {
            try readChar()
            if let c1 = char {
                if c1 == .slash {
                    try reader.seek(to: c0Loc)
                    return try readLineComment()
                } else if c1 == .star {
                    try reader.seek(to: c0Loc)
                    return try readBlockComment()
                }
            }
            throw invalidCharacterError(c0Loc, c0)
        } else if c0 == .minus || c0.isDigit {
            return try readNumber()
        } else if c0 == .doubleQuote {
            return try readString()
        } else if c0.isAlpha {
            return try readKeyword()
        } else if c0 == .leftBracket {
            try readChar()
            return buildToken(start: start, kind: .leftBracket)
        } else if c0 == .rightBracket {
            try readChar()
            return buildToken(start: start, kind: .rightBracket)
        } else if c0 == .leftBrace {
            try readChar()
            return buildToken(start: start, kind: .leftBrace)
        } else if c0 == .rightBrace {
            try readChar()
            return buildToken(start: start, kind: .rightBrace)
        } else if c0 == .comma {
            try readChar()
            return buildToken(start: start, kind: .comma)
        } else if c0 == .colon {
            try readChar()
            return buildToken(start: start, kind: .colon)
        } else {
            throw invalidCharacterError(c0Loc, c0)
        }
    }
    
    public func readLineComment() throws -> JSONToken {
        let start = location
        
        let ac0Loc = location
        guard let ac0 = try readChar() else {
            throw unexceptedEndError(ac0Loc)
        }
        guard ac0 == .slash else {
            throw invalidCharacterError(ac0Loc, ac0)
        }
        
        let ac1Loc = location
        guard let ac1 = try readChar() else {
            throw unexceptedEndError(ac1Loc)
        }
        guard ac1 == .slash else {
            throw invalidCharacterError(ac1Loc, ac1)
        }
        
        while true {
            guard let c0 = char else {
                return buildToken(start: start, kind: .lineComment)
            }
            if c0 == .cr || c0 == .lf {
                return buildToken(start: start, kind: .lineComment)
            } else {
                try readChar()
            }
        }
    }
    
    public func readBlockComment() throws -> JSONToken {
        let start = location
        
        let ac0Loc = location
        guard let ac0 = try readChar() else {
            throw unexceptedEndError(ac0Loc)
        }
        guard ac0 == .slash else {
            throw invalidCharacterError(ac0Loc, ac0)
        }
        
        let ac1Loc = location
        guard let ac1 = try readChar() else {
            throw unexceptedEndError(ac1Loc)
        }
        guard ac1 == .star else {
            throw invalidCharacterError(ac1Loc, ac1)
        }
        
        while true {
            guard let c0 = try readChar() else {
                return buildToken(start: start, kind: .blockComment)
            }
            if c0 == .star {
                guard let c1 = try readChar() else {
                    return buildToken(start: start, kind: .blockComment)
                }
                if c1 == .slash {
                    return buildToken(start: start, kind: .blockComment)
                }
            }
        }
    }
    
    public func readNumber() throws -> JSONToken {
        let start = location
        
        let c0Loc = location
        guard let c0 = char else {
            throw unexceptedEndError(c0Loc)
        }
        
        if c0 == .minus {
            try readChar()
        }
        
        let c1Loc = location
        guard let c1 = char else {
            throw unexceptedEndError(c1Loc)
        }
        
        if c1 == .num0 {
            try readChar()
        } else if c1.isDigit1To9 {
            try readChar()
            
            while true {
                if let c2 = char,
                    c2.isDigit
                {
                    try readChar()
                } else {
                    break
                }
            }
        } else {
            throw invalidCharacterError(c1Loc, c1)
        }
        
        guard let c2 = char else {
            return try buildNumberToken(start: start)
        }
        
        if c2 == .dot {
            try readChar()
            
            while true {
                if let c3 = char,
                    c3.isDigit
                {
                    try readChar()
                } else {
                    break
                }
            }
        }
        
        guard let c3 = char else {
            return try buildNumberToken(start: start)
        }
        
        if c3 == .alphaSE || c3 == .alphaLE {
            try readChar()
            
            if let c4 = char,
                c4 == .plus || c4 == .minus
            {
                try readChar()
            }
            
            while true {
                if let c5 = char,
                    c5.isDigit
                {
                    try readChar()
                } else {
                    break
                }
            }
        }
        
        return try buildNumberToken(start: start)
    }
    
    private func readString() throws -> JSONToken {
        let start = location
        
        let c0Loc = location
        guard let c0 = try readChar() else {
            throw Error.unexceptedEnd(c0Loc.with(file: file))
        }
        guard c0 == .doubleQuote else {
            throw invalidCharacterError(c0Loc, c0)
        }
        
        func unescape(start: SourceLocationLite) throws -> (string: String, consumedSize: Int) {
            do {
                return try JSONStringEscape
                    .unescapingDecode(data: reader.data,
                                      start: start.offset,
                                      size: reader.size,
                                      buffer: unescapingBuffer)
            } catch {
                throw Error.stringUnescapeError(start.with(file: file), error)
            }
        }

        var loc = self.location
        let (string, consumedSize) = try unescape(start: loc)
        loc.addColumn(length: consumedSize)
        try seek(to: loc)
        
        let c1Loc = location
        guard let c1 = try readChar() else {
            throw unexceptedEndError(c1Loc)
        }
        guard c1 == .doubleQuote else {
            throw invalidCharacterError(c1Loc, c1)
        }
        
        return buildToken(start: start,
                          kind: .string,
                          string: string)
    }
    
    private func readKeyword() throws -> JSONToken {
        let start = location
        
        let c0Loc = location
        guard let c0 = try readChar() else {
            throw unexceptedEndError(c0Loc)
        }
        guard c0.isAlpha else {
            throw invalidCharacterError(c0Loc, c0)
        }
        
        while true {
            if let c1 = char,
                c1.isAlpha
            {
                try readChar()
            } else {
                let string = try decodeUTF8(start: start)
                return buildToken(start: start,
                                  kind: .keyword,
                                  string: string)
            }
        }
    }
    
    private func buildNumberToken(start: SourceLocationLite) throws -> JSONToken {
        let string = try decodeUTF8(start: start)
        return buildToken(start: start, kind: .number, string: string)
    }

    private func buildToken(start: SourceLocationLite,
                            kind: JSONToken.Kind,
                            string: String? = nil) -> JSONToken
    {
        return JSONToken(location: start,
                         length: location.offset - start.offset,
                         kind: kind,
                         string: string)
    }

    private func decodeUTF8(start: SourceLocationLite)
        throws -> String
    {
        let offset = start.offset
        let length = location.offset - offset
        
        guard offset + length <= reader.size else {
            fatalError("out of range")
        }
        
        let data = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: reader.data.advanced(by: offset)),
                        count: length,
                        deallocator: .none)
        
        guard let str = String(data: data, encoding: .utf8) else {
            throw UTF8Reader.Error.utf8DecodeError(start.with(file: file), nil)
        }
        return str
    }
    
    private func invalidCharacterError(_ location: SourceLocationLite, _ code: Unicode.Scalar) -> Error {
        return Error.invalidCharacter(location.with(file: file), code)
    }
    
    private func unexceptedEndError(_ location: SourceLocationLite) -> Error {
        return Error.unexceptedEnd(location.with(file: file))
    }
}
