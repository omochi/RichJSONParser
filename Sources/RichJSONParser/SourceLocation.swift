import Foundation

public struct SourceLocation : Equatable, CustomStringConvertible, Codable {
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
    
    public mutating func addColumn(length: Int) {
        self = addingColumn(length: length)
    }
    
    public func addingColumn(length: Int) -> SourceLocation {
        return SourceLocation(offset: offset + length,
                              line: line,
                              columnInByte: columnInByte + length)
    }
    
    public static func + (a: SourceLocation, b: Int) -> SourceLocation {
        return a.addingColumn(length: b)
    }
}
