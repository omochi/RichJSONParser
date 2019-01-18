import OrderedDictionary

public enum JSON : Equatable, Hashable {
    case null
    case boolean(Bool)
    case number(String)
    case string(String)
    case array([JSON])
    case object(OrderedDictionary<String, JSON>)
}
