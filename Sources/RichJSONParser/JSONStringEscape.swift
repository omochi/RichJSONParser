import Foundation

public enum JSONStringEscape {
    public enum Error : LocalizedError {
        case unexceptedEnd(offset: Int)
        case invalidCharacter(offset: Int, Unicode.Scalar)
        case invalidCodePoint(offset: Int, UInt32)
        case utf8DecodeError(offset: Int)
        
        public var errorDescription: String? {
            switch self {
            case .unexceptedEnd(offset: let o):
                return "unexcepted end of data at \(o)"
            case .invalidCharacter(offset: let o, let ch):
                return "invalid character (\(ch.debugDescription)) at \(o)"
            case .invalidCodePoint(offset: let o, let c):
                let cs = c.format("U+%04X")
                return "invalid unicode code point (\(cs)) at \(o)"
            case .utf8DecodeError(offset: let o):
                return "utf8 decode failed at \(o)"
            }
        }
    }
    
    public static func unescape(data: Data) throws -> String {
        var result = String()
        
        var offset = 0

        if let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data),
            c0.codePoint == .doubleQuote {
            offset += 1
        }
        
        while true {
            guard let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                return result
            }
            
            if c0.codePoint == .doubleQuote {
                return result
            } else if c0.codePoint == .backSlash {
                let escapeStart = offset
                offset += 1
                guard let c1 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                    throw Error.unexceptedEnd(offset: offset)
                }
            
                let c1c = c1.codePoint
                if c1c == .doubleQuote {
                    offset += 1
                    result.append("\"")
                } else if c1c == .backSlash {
                    offset += 1
                    result.append("\\")
                } else if c1c == .alphaSB {
                    offset += 1
                    result.append(String(.backSpace))
                } else if c1c == .alphaSF {
                    offset += 1
                    result.append(String(.formFeed))
                } else if c1c == .alphaSN {
                    offset += 1
                    result.append("\n")
                } else if c1c == .alphaSR {
                    offset += 1
                    result.append("\r")
                } else if c1c == .alphaST {
                    offset += 1
                    result.append("\t")
                } else if c1c == .alphaSU {
                    offset += 1
                    var value: UInt32 = 0
                    for _ in 0..<4 {
                        guard let c2 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                            throw Error.unexceptedEnd(offset: offset)
                        }
                        guard c2.codePoint.isHex else {
                            throw Error.invalidCharacter(offset: offset, c2.codePoint)
                        }
                        value = value * 16 + UInt32(c2.codePoint.hexValue!)
                        offset += 1
                    }
                    guard let char = Unicode.Scalar(value) else {
                        throw Error.invalidCodePoint(offset: escapeStart, value)
                    }
                    result.append(String(char))
                } else {
                    throw Error.invalidCharacter(offset: offset, c1c)
                }
            } else if c0.codePoint.isControlCode {
                throw Error.invalidCharacter(offset: offset, c0.codePoint)
            } else {
                let start = data.startIndex + offset
                let end = start + c0.length
                
                guard let str = String(data: data[start..<end], encoding: .utf8) else {
                    throw Error.utf8DecodeError(offset: offset)
                }
                
                result.append(str)
                offset += c0.length
            }
        }
    }
    
    public static func escape(string: String) -> Data {
        var result = Data()
        let view = string.unicodeScalars
        var offset = view.startIndex
        while true {
            guard offset < view.endIndex else {
                return result
            }
            let c0c = view[offset]
            offset = view.index(after: offset)
            if c0c == .doubleQuote {
                result.append(contentsOf: "\\\"".utf8)
            } else if c0c == .backSlash {
                result.append(contentsOf: "\\\\".utf8)
            } else if c0c == .backSpace {
                result.append(contentsOf: "\\b".utf8)
            } else if c0c == .formFeed {
                result.append(contentsOf: "\\f".utf8)
            } else if c0c == .cr {
                result.append(contentsOf: "\\r".utf8)
            } else if c0c == .lf {
                result.append(contentsOf: "\\n".utf8)
            } else if c0c == .tab {
                result.append(contentsOf: "\\t".utf8)
            } else if c0c.isASCII && !c0c.isControlCode {
                result.append(contentsOf: String(c0c).utf8)
            } else {
                let hex = String(format: "%04X", c0c.value)
                let str = "\\u\(hex)"
                result.append(contentsOf: str.utf8)
            }
        }
    }
}
