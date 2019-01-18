import OrderedDictionary

public struct ParsedJSON : Equatable {
    public enum Value : Equatable {
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

extension ParsedJSON {
    public func toJSON() -> JSON {
        switch self.value {
        case .null: return .null
        case .boolean(let b): return .boolean(b)
        case .number(let s): return .number(s)
        case .string(let s): return .string(s)
        case .array(let a):
            return .array(a.map { $0.toJSON() })
        case .object(let o):
            return .object(o.mapValues { $0.toJSON() })
        }
    }
}
