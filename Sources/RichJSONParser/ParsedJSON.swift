import OrderedDictionary

public struct ParsedJSON {
    public enum Value {
        case null
        case boolean(Bool)
        case number(String)
        case string(String)
        case array([ParsedJSON])
        case object(OrderedDictionary<String, ParsedJSON>)
    }
    
    public var location: SourceLocation
    public var value: Value
    
    public init(location: SourceLocation,
                value: Value)
    {
        self.location = location
        self.value = value
    }
}
