public struct JSONToken : Equatable {
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
    
    public var location: SourceLocation
    public var length: Int
    public var kind: Kind
    
    public init(location: SourceLocation,
                length: Int,
                kind: Kind)
    {
        self.location = location
        self.length = length
        self.kind = kind
    }
}

