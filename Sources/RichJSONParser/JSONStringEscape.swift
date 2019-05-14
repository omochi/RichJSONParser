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
        let data = try unescapeData(data: data, size: size)
        guard let string = String(data: data as Data, encoding: .utf8) else {
            throw Error.utf8DecodeError(offset: nil)
        }
        return string
    }
    
    public static func unescapeData(data: UnsafePointer<UInt8>, size: Int)
        throws -> NSData
    {
        var offset = 0
        
        if let c0 = try UTF8Decoder.decodeUTF8(at: 0, from: data, size: size),
            c0.codePoint == .doubleQuote
        {
            offset += 1
        }
        
        let buffer = StaticBuffer(capacity: 0)
        let result = try unescapingDecodeData(data: data, start: offset, size: size,
                                              buffer: buffer)
        // drop null
        return NSData(bytes: result.data,
                      length: result.dataSize - 1)
    }
    
    public static func unescapingDecode(data: UnsafePointer<UInt8>,
                                        start: Int,
                                        size: Int,
                                        buffer: StaticBuffer)
        throws -> (string: String, consumedSize: Int)
    {
        let data = try unescapingDecodeData(data: data, start: start, size: size,
                                            buffer: buffer)
        let string = String(cString: data.data)
        return (string: string, consumedSize: data.consumedSize)
    }

    // null terminated
    // dataSize includes null byte
    public static func unescapingDecodeData(data: UnsafePointer<UInt8>,
                                            start: Int,
                                            size: Int,
                                            buffer: StaticBuffer)
        throws -> (data: UnsafePointer<UInt8>, dataSize: Int, consumedSize: Int)
    {
        let resultStart = buffer.current
        
        func write(_ byte: UInt8) {
            buffer.write(byte: byte)
        }
        
        var offset: Int = start
        
        while true {
            guard let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
                break
            }
            
            if c0.codePoint == .doubleQuote {
                break
            } else if c0.codePoint == .backSlash {
                offset += 1
                guard let c1 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
                    throw Error.unexceptedEnd(offset: offset)
                }
            
                let c1c = c1.codePoint
                if c1c == .doubleQuote {
                    offset += 1
                    write(.doubleQuote)
                } else if c1c == .backSlash {
                    offset += 1
                    write(.backSlash)
                } else if c1c == .slash {
                    offset += 1
                    write(.slash)
                } else if c1c == .alphaSB {
                    offset += 1
                    write(.backSpace)
                } else if c1c == .alphaSF {
                    offset += 1
                    write(.formFeed)
                } else if c1c == .alphaSN {
                    offset += 1
                    write(.lf)
                } else if c1c == .alphaSR {
                    offset += 1
                    write(.cr)
                } else if c1c == .alphaST {
                    offset += 1
                    write(.tab)
                } else if c1c == .alphaSU {
                    offset -= 1
                    
                    let hex0 = try decodeUnicodeHex(data: data, start: offset, size: size)
                    if hex0.code.isLowSurrogate {
                        throw Error.invalidCodePoint(offset: offset, hex0.code)
                    }
              
                    guard hex0.code.isHighSurrogate else {
                        guard let char = Unicode.Scalar(hex0.code) else {
                            throw Error.invalidCodePoint(offset: offset, hex0.code)
                        }
                        
                        offset += hex0.consumedSize
                        
                        let utf8 = String(char).data(using: .utf8)!
                        for byte in utf8 {
                            write(byte)
                        }
                        continue
                    }
                    
                    offset += hex0.consumedSize
                    
                    let hex1 = try decodeUnicodeHex(data: data, start: offset, size: size)
                    guard hex1.code.isLowSurrogate else {
                        throw Error.invalidCodePoint(offset: offset, hex1.code)
                    }
                    
                    let code = UInt32.combineSurrogates(high: hex0.code,
                                                        low: hex1.code)
                    guard let char = Unicode.Scalar(code) else
                    {
                        throw Error.invalidCodePoint(offset: offset, hex1.code)
                    }
                    
                    offset += hex1.consumedSize
                    
                    let utf8 = String(char).data(using: .utf8)!
                    for byte in utf8 {
                        write(byte)
                    }
                } else {
                    throw Error.invalidCharacter(offset: offset, c1c)
                }
            } else if c0.codePoint.isControlCode {
                throw Error.invalidCharacter(offset: offset, c0.codePoint)
            } else {
                for _ in 0..<c0.length {
                    write(data.advanced(by: offset).pointee)
                    offset += 1
                }
            }
        }
        
        // null
        write(0)
        
        return (data: UnsafePointer(buffer.memory.advanced(by: resultStart)),
                dataSize: buffer.current - resultStart,
                consumedSize: offset - start)
    }
    
    public static func decodeUnicodeHex(data: UnsafePointer<UInt8>,
                                        start: Int,
                                        size: Int)
        throws -> (code: UInt32, consumedSize: Int)
    {
        var offset = start
        
        guard let c0 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
            throw Error.unexceptedEnd(offset: offset) }
        guard c0.codePoint == .backSlash else {
            throw Error.invalidCharacter(offset: offset, c0.codePoint) }
        offset += 1
    
        guard let c1 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
            throw Error.unexceptedEnd(offset: offset) }
        guard c1.codePoint == .alphaSU else {
            throw Error.invalidCharacter(offset: offset, c0.codePoint) }
        offset += 1
        
        var code: UInt32 = 0
        for _ in 0..<4 {
            guard let c2 = try UTF8Decoder.decodeUTF8(at: offset, from: data, size: size) else {
                throw Error.unexceptedEnd(offset: offset)
            }
            guard c2.codePoint.isHex else {
                throw Error.invalidCharacter(offset: offset, c2.codePoint)
            }
            code = code * 16 + UInt32(c2.codePoint.hexValue!)
            offset += 1
        }
        return (code: code, consumedSize: offset - start)
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
            } else if c0c.isControlCode {
                let str = String(format: "\\u%04X", c0c.value)
                result.append(contentsOf: str.utf8)
            } else {
                result.append(contentsOf: String(c0c).utf8)
            }
        }
    }
}

extension NSMutableData {
    internal func append(byte: UInt8) {
        withUnsafePointer(to: byte) { (p) in
            self.append(p, length: 1)
        }
    }
    
    internal func appendByte(_ byte: UInt8) {
        withUnsafePointer(to: byte) { (p) in
            self.append(p, length: 1)
        }
    }
}
