import Foundation

public struct SourceLocation : Equatable, CustomStringConvertible, Codable {
    public var offset: Int
    public var line: Int
    public var columnInByte: Int
    public var file: URL?
    
    public init(offset: Int,
                line: Int,
                columnInByte: Int,
                file: URL?)
    {
        if let file = file {
            precondition(file.isFileURL)
        }
        
        self.offset = offset
        self.line = line
        self.columnInByte = columnInByte
        self.file = file
    }
    
    public var description: String {
        var d = "\(line):\(columnInByte)(\(offset))"
        if let file = file {
            d += " in \(file.relativePath)"
        }
        return d
    }
    
    public init() {
        self.init(offset: 0,
                  line: 1,
                  columnInByte: 1,
                  file: nil)
    }
    
    public mutating func addLine(newLineLength: Int) {
        self.offset += newLineLength
        self.line += 1
        self.columnInByte = 1
    }
    
    public func addingLine(newLineLength: Int) -> SourceLocation {
        var o = self
        o.addLine(newLineLength: newLineLength)
        return o
    }
    
    public mutating func addColumn(length: Int) {
        self.offset += length
        self.columnInByte += length
    }
    
    public func addingColumn(length: Int) -> SourceLocation {
        var o = self
        o.addColumn(length: length)
        return o
    }
    
    public static func + (a: SourceLocation, b: Int) -> SourceLocation {
        return a.addingColumn(length: b)
    }
}
