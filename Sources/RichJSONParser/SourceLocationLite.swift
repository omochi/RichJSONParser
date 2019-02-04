import Foundation

public struct SourceLocationLite : Equatable, CustomStringConvertible {
    public var offset: Int
    public var line: Int
    public var columnInByte: Int
    
    public init(offset: Int,
                line: Int,
                columnInByte: Int)
    {
        self.offset = offset
        self.line = line
        self.columnInByte = columnInByte
    }
    
    public var description: String {
        return "\(line):\(columnInByte)(\(offset))"
    }
    
    public init() {
        self.init(offset: 0,
                  line: 1,
                  columnInByte: 1)
    }
    
    public mutating func addLine(newLineLength: Int) {
        self.offset += newLineLength
        self.line += 1
        self.columnInByte = 1
    }
    
    public func addingLine(newLineLength: Int) -> SourceLocationLite {
        var o = self
        o.addLine(newLineLength: newLineLength)
        return o
    }
    
    public mutating func addColumn(length: Int) {
        self.offset += length
        self.columnInByte += length
    }
    
    public func addingColumn(length: Int) -> SourceLocationLite {
        var o = self
        o.addColumn(length: length)
        return o
    }
    
    public mutating func addOffset(length: Int) {
        self.offset += length
    }
    
    public func addingOffset(length: Int) -> SourceLocationLite {
        var o = self
        o.addOffset(length: length)
        return o
    }
    
    public func with(file: URL?) -> SourceLocation {
        return SourceLocation(self, file: file)
    }
}
