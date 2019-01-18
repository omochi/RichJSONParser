public struct JSONArray : Equatable {
    public var value: [JSON]
    
    public init(_ value: [JSON] = []) {
        self.value = value
    }
}
