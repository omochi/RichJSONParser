import Foundation

public enum JSONStringEscape {
    public enum Error : LocalizedError, CustomStringConvertible {
        case unexceptedEnd(offset: Int)
        case invalidCharacter(offset: Int, Unicode.Scalar)
        case invalidCodePoint(offset: Int, UInt32)
        case utf8DecodeError(offset: Int?)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .unexceptedEnd(offset: let o):
                return "unexcepted end of data at \(o)"
            case .invalidCharacter(offset: let o, let ch):
                return "invalid character (\(ch.debugDescription)) at \(o)"
            case .invalidCodePoint(offset: let o, let c):
                let cs = c.format("U+%04X")
                return "invalid unicode code point (\(cs)) at \(o)"
            case .utf8DecodeError(offset: let o):
                return ["utf8 decode failed",
                        o.map { "at \($0)" }]
                    .compactMap { $0 }.joined(separator: " ")
            }
        }
    }
    
    public static func unescape(data: Data) throws -> String {
        return try data.withUnsafeBytes { (p) in
            try unescape(data: p, size: data.count)
        }
    }
    
    public static func unescape(data: UnsafePointer<UInt8>, size: Int) throws -> String {
        let nsStrData = try _unescape(data: data, size: size)
        
        let strData = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: nsStrData.bytes),
                           count: nsStrData.length,
                           deallocator: Data.Deallocator.none)
        
        guard let string = String(data: strData, encoding: .utf8) else {
            throw Error.utf8DecodeError(offset: nil)
        }
        return string
    }
    
    public static func _unescape(data: UnsafePointer<UInt8>, size: Int) throws -> NSData {
        let result = NSMutableData(capacity: size)!
        
        var offset = 0

        if let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size),
            c0.codePoint == .doubleQuote {
            offset += 1
        }
        
        while true {
            guard let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
                return result
            }
            
            if c0.codePoint == .doubleQuote {
                return result
            } else if c0.codePoint == .backSlash {
                let escapeStart = offset
                offset += 1
                guard let c1 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
                    throw Error.unexceptedEnd(offset: offset)
                }
            
                let c1c = c1.codePoint
                if c1c == .doubleQuote {
                    offset += 1
                    result.appendByte(.doubleQuote)
                } else if c1c == .backSlash {
                    offset += 1
                    result.appendByte(.backSlash)
                } else if c1c == .alphaSB {
                    offset += 1
                    result.appendByte(.backSpace)
                } else if c1c == .alphaSF {
                    offset += 1
                    result.appendByte(.formFeed)
                } else if c1c == .alphaSN {
                    offset += 1
                    result.appendByte(.lf)
                } else if c1c == .alphaSR {
                    offset += 1
                    result.appendByte(.cr)
                } else if c1c == .alphaST {
                    offset += 1
                    result.appendByte(.tab)
                } else if c1c == .alphaSU {
                    offset += 1
                    var value: UInt32 = 0
                    for _ in 0..<4 {
                        guard let c2 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
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
                    let utf8 = String(char).data(using: .utf8)!
                    result.append(utf8)
                } else {
                    throw Error.invalidCharacter(offset: offset, c1c)
                }
            } else if c0.codePoint.isControlCode {
                throw Error.invalidCharacter(offset: offset, c0.codePoint)
            } else {
                result.append(data.advanced(by: offset), length: c0.length)
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

extension NSMutableData {
    internal func appendByte(_ byte: UInt8) {
        withUnsafePointer(to: byte) { (p) in
            self.append(p, length: 1)
        }
    }
}
