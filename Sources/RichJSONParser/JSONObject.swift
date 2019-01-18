import OrderedDictionary

public struct JSONObject : Equatable {
    public var value: OrderedDictionary<String, JSON>
    
    public init(_ value: OrderedDictionary<String, JSON> = OrderedDictionary()) {
        self.value = value
    }
}
