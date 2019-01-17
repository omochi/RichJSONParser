import Foundation

public enum JSONStringEscape {
    public enum Error : Swift.Error, CustomStringConvertible {
        case unexceptedEnd(offset: Int)
        case invalidCharacter(offset: Int, Unicode.Scalar)
        case invalidCodePoint(offset: Int, UInt32)
        
        public var description: String {
            switch self {
            case .unexceptedEnd(offset: let o):
                return "unexcepted end of data at \(o)"
            case .invalidCharacter(offset: let o, let ch):
                return "invalid character (\(ch.debugDescription)) at \(o)"
            case .invalidCodePoint(offset: let o, let c):
                let hex = String(format: "0x%04X", c)
                return "invalid unicode code point (\(hex)) at \(o)"
            }
        }
    }
    
    public static func unescape(data: Data) throws -> Data {
        var result = Data()
        
        var offset = 0
        while true {
            guard let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                return result
            }
            
            if c0.codePoint == .backSlash {
                let escapeStart = offset
                offset += 1
                guard let c1 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                    throw Error.unexceptedEnd(offset: offset)
                }
            
                let c1c = c1.codePoint
                if c1c == .doubleQuote {
                    offset += 1
                    result.append(.doubleQuote)
                } else if c1c == .backSlash {
                    offset += 1
                    result.append(.backSlash)
                } else if c1c == .alphaSB {
                    offset += 1
                    result.append(.backSpace)
                } else if c1c == .alphaSF {
                    offset += 1
                    result.append(.formFeed)
                } else if c1c == .alphaSN {
                    offset += 1
                    result.append(.lf)
                } else if c1c == .alphaSR {
                    offset += 1
                    result.append(.cr)
                } else if c1c == .alphaST {
                    offset += 1
                    result.append(.tab)
                } else if c1c == .alphaSU {
                    offset += 1
                    var value: UInt32 = 0
                    for _ in 0..<4 {
                        guard let c2 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                            throw Error.unexceptedEnd(offset: offset)
                        }
                        guard c2.codePoint.isHex() else {
                            throw Error.invalidCharacter(offset: offset, c2.codePoint)
                        }
                        value = value * 16 + UInt32(c2.codePoint.hexValue()!)
                        offset += 1
                    }
                    guard let char = Unicode.Scalar(value) else {
                        throw Error.invalidCodePoint(offset: escapeStart, value)
                    }
                    result.append(contentsOf: String(char).utf8)
                } else {
                    throw Error.invalidCharacter(offset: offset + 1, c1c)
                }
            } else if c0.codePoint.isControlCode() {
                throw Error.invalidCharacter(offset: offset, c0.codePoint)
            } else {
                let start = data.index(data.startIndex, offsetBy: offset)
                let end = data.index(start, offsetBy: c0.length)
                offset += c0.length
                result.append(contentsOf: data[start..<end])
            }
        }
    }
    
    public static func escape(data: Data) throws -> Data {
        var result = Data()
        var offset = 0
        while true {
            guard let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data) else {
                return result
            }
            let c0c = c0.codePoint
            if c0c == .doubleQuote {
                offset += 1
                result.append(contentsOf: "\\\"".utf8)
            } else if c0c == .backSlash {
                offset += 1
                result.append(contentsOf: "\\\\".utf8)
            } else if c0c == .backSpace {
                offset += 1
                result.append(contentsOf: "\\b".utf8)
            } else if c0c == .formFeed {
                offset += 1
                result.append(contentsOf: "\\f".utf8)
            } else if c0c == .cr {
                offset += 1
                result.append(contentsOf: "\\r".utf8)
            } else if c0c == .lf {
                offset += 1
                result.append(contentsOf: "\\n".utf8)
            } else if c0c == .tab {
                offset += 1
                result.append(contentsOf: "\\t".utf8)
            } else if c0c.isASCII && !c0c.isControlCode() {
                let start = data.index(data.startIndex, offsetBy: offset)
                let end = data.index(start, offsetBy: c0.length)
                offset += c0.length
                result.append(contentsOf: data[start..<end])
            } else {
                let hex = String(format: "%04X", c0c.value)
                let str = "\\u\(hex)"
                offset += c0.length
                result.append(contentsOf: str.utf8)
            }
        }
    }
}
