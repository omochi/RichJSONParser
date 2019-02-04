public struct JSONToken : Equatable, CustomStringConvertible {
    public enum Kind {
        case end
        case newLine
        case whiteSpace
        case lineComment
        case blockComment
        case number
        case string
        case keyword
        case leftBracket
        case rightBracket
        case comma
        case leftBrace
        case rightBrace
        case colon
    }
    
    public var location: SourceLocationLite
    public var length: Int
    public var kind: Kind
    public var string: String?
    
    public init(location: SourceLocationLite,
                length: Int,
                kind: Kind,
                string: String?)
    {
        self.location = location
        self.length = length
        self.kind = kind
        self.string = string
    }
    
    public var description: String {
        return "JSONToken(\(kind), \(length) bytes, at \(location))"
    }
}

