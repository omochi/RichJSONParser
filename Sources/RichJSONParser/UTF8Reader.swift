import Foundation

public final class UTF8Reader {
    public enum Error : LocalizedError, CustomStringConvertible {
        case utf8DecodeError(SourceLocation, Swift.Error?)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .utf8DecodeError(let loc, let e):
                var d = "utf8 decode failed at \(loc)"
                if let e = e {
                    d += ", \(e)"
                }
                return d
            }
        }
    }
    
    private let _data: NSData
    public let data: UnsafePointer<UInt8>
    public let size: Int
    private var _nextLocation: SourceLocation
    private var _location: SourceLocation
    private var _char: Unicode.Scalar?
    
    public var char: Unicode.Scalar? {
        return _char
    }

    public var location: SourceLocation {
        return _location
    }
    
    public init(data: Data, file: URL? = nil) throws
    {
        _data = NSData(data: data)
        self.data = _data.bytes.assumingMemoryBound(to: UInt8.self)
        self.size = _data.length
        self._nextLocation = SourceLocation(offset: 0,
                                            line: 1,
                                            columnInByte: 1,
                                            file: file)
        _location = _nextLocation
        try _read()
    }
    
    @discardableResult
    public func read() throws -> Unicode.Scalar? {
        let char = self.char
        _location = _nextLocation
        try _read()
        return char
    }
    
    public func seek(to location: SourceLocation) throws {
        _nextLocation = location
        _location = _nextLocation
        try _read()
    }
    
    private func _read() throws {
        var location = _nextLocation
        
        do {
            guard let c0 = try UTF8Decoder.decodeUTF8(at: location.offset,
                                                      from: data,
                                                      size: size) else
            {
                _char = nil
                _nextLocation = location
                return
            }
            
            let c0c = c0.codePoint
            
            if c0c == .cr {
                if let c1 = try UTF8Decoder.decodeUTF8(at: location.offset + 1,
                                                       from: data,
                                                       size: size),
                    c1.codePoint == .lf
                {
                    location.addColumn(length: 1)
                } else {
                    location.addLine(newLineLength: 1)
                }
            } else if c0c == .lf {
                location.addLine(newLineLength: 1)
            } else {
                location.addColumn(length: c0.length)
            }
            
            _char = c0c
            _nextLocation = location
        } catch {
            throw Error.utf8DecodeError(location, error)
        }
    }
}
