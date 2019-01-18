import OrderedDictionary

public enum JSON : Equatable {
    case null
    case boolean(Bool)
    case number(String)
    case string(String)
    case array([JSON])
    case object(OrderedDictionary<String, JSON>)
}
