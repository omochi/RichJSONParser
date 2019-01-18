import OrderedDictionary

public enum JSON : Equatable, Hashable {
    case null
    case boolean(Bool)
    case number(String)
    case string(String)
    case array([JSON])
    case object(OrderedDictionary<String, JSON>)
    
    public var kind : Kind {
        switch self {
        case .null: return .null
        case .boolean: return .boolean
        case .number: return .number
        case .string: return .string
        case .array: return .array
        case .object: return .object
        }
    }
    
    public enum Kind : String {
        case null
        case boolean
        case number
        case string
        case array
        case object
    }
}
