import Foundation

public enum UTF8Decoder {
    public enum Error : Swift.Error, CustomStringConvertible {
        case invalidByte(UInt8)
        case invalidLength(Int8)
        case invalidCodePoint(UInt32)
        case unexceptedHead(offset: Int8)
        case unexceptedBody
        case unexceptedEnd(offset: Int8)
        
        public var description: String {
            switch self {
            case .invalidByte(let b):
                return String(format: "invalid byte: %02x", b)
            case .invalidLength(let len):
                return String(format: "invalid length: %d", len)
            case .invalidCodePoint(let c):
                return String(format: "invalid code point: %04x", c)
            case .unexceptedHead(let o):
                return String(format: "unexcepted head byte at %d", o)
            case .unexceptedBody:
                return String(format: "unexcepted body byte at start")
            case .unexceptedEnd(let o):
                return String(format: "unexcepted end at %d", o)
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

    static func readUTF8(at start: Int, from data: Data) throws -> DecodedUnicodeChar? {
        guard start < data.count else {
            return nil
        }
        
        let b0 = data[start]
        switch ByteKind(byte: b0) {
        case .head(length: let length):
            switch length {
            case 1:
                return DecodedUnicodeChar(codePoint: Unicode.Scalar(b0), length: 1)
            case 2, 3, 4:
                var value: UInt32 = UInt32((b0 << length) >> length)
                
                guard start + Int(length) - 1 < data.count else {
                    throw Error.unexceptedEnd(offset: length - 1)
                }

                for offset in 1..<length {
                    let b1 = data[start + Int(offset)]
                    switch ByteKind(byte: b1) {
                    case .head:
                        throw Error.unexceptedHead(offset: offset)
                    case .body:
                        value = (value << 6) + UInt32(b1 & 0b0011_1111)
                    case .invalid:
                        throw Error.invalidByte(b1)
                    }
                }
                guard let codePoint = Unicode.Scalar(value) else {
                    throw Error.invalidCodePoint(value)
                }
                
                return DecodedUnicodeChar(codePoint: codePoint, length: Int(length))
            default:
                throw Error.invalidLength(length)
            }
        case .body:
            throw Error.unexceptedBody
        case .invalid:
            throw Error.invalidByte(b0)
        }
    }
}
