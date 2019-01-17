import OrderedDictionary

public class JSONNode {
    public enum JSON {
        case null
        case boolean(Bool)
        case number(String)
        case string(String)
        case array([JSONNode])
        case object(OrderedDictionary<String, JSONNode>)
    }
    
    public let location: SourceLocation
    public let json: JSON
    
    public init(location: SourceLocation,
                json: JSON)
    {
        self.location = location
        self.json = json
    }
}
