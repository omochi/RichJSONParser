import Foundation

public enum UTF8Decoder {
    public enum Error : LocalizedError {
        case invalidByte(offset: Int, UInt8)
        case invalidLength(offset: Int, Int8)
        case invalidCodePoint(offset: Int, UInt32)
        case unexceptedHead(offset: Int)
        case unexceptedBody(offset: Int)
        case unexceptedEnd(offset: Int)
        
        public var errorDescription: String? {
            switch self {
            case .invalidByte(let o, let b):
                let bs = b.format("0x%02X")
                return "invalid byte (\(bs)) at \(o)"
            case .invalidLength(let o, let len):
                return "invalid length (\(len)) at \(o)"
            case .invalidCodePoint(let o, let c):
                let cs = c.format("U+%04X")
                return "invalid code point (\(cs)) at \(o)"
            case .unexceptedHead(let o):
                return "unexcepted head byte at \(o)"
            case .unexceptedBody(let o):
                return "unexcepted body byte at \(o)"
            case .unexceptedEnd(let o):
                return "unexcepted end at \(o)"
            }
        }
    }
}

internal extension UTF8Decoder {
    enum ByteKind {
        case head(length: Int8)
        case body
        case invalid
        
        public init(byte: UInt8) {
            if byte & 0b1000_0000 == 0b0000_0000 {
                self = .head(length: 1)
            } else if byte & 0b1100_0000 == 0b1000_0000 {
                self = .body
            } else if byte & 0b1110_0000 == 0b1100_0000 {
                self = .head(length: 2)
            } else if byte & 0b1111_0000 == 0b1110_0000 {
                self = .head(length: 3)
            } else if byte & 0b1111_1000 == 0b1111_0000 {
                self = .head(length: 4)
            } else {
                self = .invalid
            }
        }
    }

    static func decodeUTF8(at start: Int, from data: Data) throws -> DecodedUnicodeChar? {
        func read(_ offset: Int) -> UInt8? {
            guard data.startIndex + offset < data.endIndex else {
                return nil
            }
            return data[data.startIndex + offset]
        }

        guard let b0 = read(start) else {
            return nil
        }

        switch ByteKind(byte: b0) {
        case .head(length: let length):
            switch length {
            case 1:
                return DecodedUnicodeChar(codePoint: Unicode.Scalar(b0), length: 1)
            case 2, 3, 4:
                var value: UInt32 = UInt32((b0 << length) >> length)
                
                for i in 0..<(Int(length) - 1) {
                    let position = start + i + 1
                    guard let b1 = read(position) else {
                        throw Error.unexceptedEnd(offset: position)
                    }
                    switch ByteKind(byte: b1) {
                    case .head:
                        throw Error.unexceptedHead(offset: position)
                    case .body:
                        value = (value << 6) + UInt32(b1 & 0b0011_1111)
                    case .invalid:
                        throw Error.invalidByte(offset: position, b1)
                    }
                }
                guard let codePoint = Unicode.Scalar(value) else {
                    throw Error.invalidCodePoint(offset: start, value)
                }
                
                return DecodedUnicodeChar(codePoint: codePoint, length: Int(length))
            default:
                throw Error.invalidLength(offset: start, length)
            }
        case .body:
            throw Error.unexceptedBody(offset: start)
        case .invalid:
            throw Error.invalidByte(offset: start, b0)
        }
    }
}
