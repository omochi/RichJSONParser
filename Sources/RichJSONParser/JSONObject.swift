import OrderedDictionary

public struct JSONObject {
    public var value: OrderedDictionary<String, JSON>
    
    public init(_ value: OrderedDictionary<String, JSON>) {
        self.value = value
    }
}
