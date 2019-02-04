import Foundation

// preserve keys order
public struct JSONDictionary<Value> {
    public typealias Element = (key: String, value: Value)
    public typealias Index = Int

    private var items: [(key: String, value: Value)]

    public init() {
        self.items = []
    }
    
    internal init(items: [(key: String, value: Value)]) {
        self.items = items
    }
}

private enum JSONDictionaryError : LocalizedError, CustomStringConvertible {
    case keyCollision
    
    public var errorDescription: String? { return description }
    
    public var description: String {
        switch self {
        case .keyCollision: return "key collision"
        }
    }
}

extension JSONDictionary {
    public init<S>(uniqueKeysWithValues keysAndValues: S)
        where S : Sequence, S.Element == (String, Value)
    {
        self.init()
        try! merge(keysAndValues,
                   uniquingKeysWith: { _, _ in
                    throw JSONDictionaryError.keyCollision })
    }
    
    public init<S>(_ keysAndValues: S,
                   uniquingKeysWith combine: (Value, Value) throws -> Value)
        rethrows where S : Sequence, S.Element == (String, Value)
    {
        self.init()
        try merge(keysAndValues, uniquingKeysWith: combine)
    }
    
    public init(_ keyAndValues: KeyValuePairs<String, Value>) {
        self.init()
        for (k, v) in keyAndValues {
            self.items.append((key: k, value: v))
        }
    }
    
    public var keys: [String] {
        return self.items.map { $0.key }
    }
    
    public subscript(key: String) -> Value? {
        get {
            return items.first { $0.key == key }.map { $0.value }
        }
        set {
            guard let value = newValue else {
                remove(for: key)
                return
            }
            
            guard let index = self.index(for: key) else {
                items.append((key: key, value: value))
                return
            }
            
            items[index] = (key: key, value: value)
        }
    }
    
    public mutating func merge<S>(_ other: S,
                                  uniquingKeysWith combine: (Value, Value) throws -> Value)
        rethrows
        where S : Sequence, S.Element == (String, Value)
    {
        var indexDict = Dictionary<String, Int>()
        for (i, e) in items.enumerated() {
            indexDict[e.key] = i
        }
        
        for (k, v) in other {
            if let index = indexDict[k] {
                let newValue = try combine(items[index].value, v)
                items[index] = (key: k, value: newValue)
            } else {
                items.append((key: k, value: v))
            }
        }
    }
    
    public mutating func remove(for key: String) {
        items.removeAll { $0.key == key }
    }
    
    public mutating func insert(_ value: Value, for key: String, before rightKey: String?) {
        remove(for: key)
        
        guard let rightKey = rightKey,
            let rightIndex = self.index(for: rightKey) else
        {
            items.append((key: key, value: value))
            return
        }
        
        items.insert((key: key, value: value), at: rightIndex)
    }
    
    public mutating func insert(_ value: Value, for key: String, after leftKey: String) {
        remove(for: key)
        
        guard let leftIndex = self.index(for: key) else {
            items.append((key: key, value: value))
            return
        }
        
        items.insert((key: key, value: value), at: leftIndex + 1)
    }
    
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> JSONDictionary<T> {
        let items = try self.items.map { (k, v) -> (key: String, value: T) in
            let v = try transform(v)
            return (key: k, value: v)
        }
        return JSONDictionary<T>(items: items)
    }
    
    private func index(for key: String) -> Int? {
        return items.firstIndex { $0.key == key }
    }
}

extension JSONDictionary : Collection, BidirectionalCollection {
    public subscript(position: Index) -> (key: String, value: Value) {
        return items[position]
    }
    
    public var startIndex: Index {
        return 0
    }
    
    public var endIndex: Index {
        return items.count
    }
    
    public var count: Int {
        return items.count
    }
    
    public func index(after i: Index) -> Index {
        return i + 1
    }
    
    public func index(before i: Index) -> Index {
        return i - 1
    }
}

extension JSONDictionary : Equatable where Value : Equatable {
    public static func == (a: JSONDictionary<Value>, b: JSONDictionary<Value>) -> Bool {
        guard a.items.count == b.items.count else {
            return false
        }
        
        for i in 0..<a.items.count {
            guard a.items[i] == b.items[i] else {
                return false
            }            
        }
        
        return true
    }
}

extension JSONDictionary : Hashable where Value : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        
        for (k, v) in items {
            hasher.combine(k)
            hasher.combine(v)
        }
    }
}

extension JSONDictionary : CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(self, unlabeledChildren: self, displayStyle: .dictionary)
    }
}

