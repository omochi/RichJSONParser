import OrderedDictionary

public struct ParsedJSON : Equatable {
    public enum Value : Equatable {
        case null
        case boolean(Bool)
        case number(String)
        case string(String)
        case array([ParsedJSON])
        case object(OrderedDictionary<String, ParsedJSON>)
        
        public var kind : JSON.Kind {
            switch self {
            case .null: return .null
            case .boolean: return .boolean
            case .number: return .number
            case .string: return .string
            case .array: return .array
            case .object: return .object
            }
        }
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

extension JSON {
    public func toParsedJSON(dummyLocation loc: SourceLocation) -> ParsedJSON {
        switch self {
        case .null: return ParsedJSON(location: loc, value: .null)
        case .boolean(let b): return ParsedJSON(location: loc, value: .boolean(b))
        case .number(let s): return ParsedJSON(location: loc, value: .number(s))
        case .string(let s): return ParsedJSON(location: loc, value: .string(s))
        case .array(let a):
            return ParsedJSON(location: loc,
                              value: .array(a.map { $0.toParsedJSON(dummyLocation: loc) }))
        case .object(let o):
            return ParsedJSON(location: loc,
                              value: .object(o.mapValues { $0.toParsedJSON(dummyLocation: loc) }))
            
        }
    }
}

