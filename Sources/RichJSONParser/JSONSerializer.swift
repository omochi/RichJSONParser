import Foundation

public struct JSONSerializeOptions : Equatable {
    public var isPrettyPrint: Bool
    public var indentString: String
    
    public init(isPrettyPrint: Bool = true,
                indentString: String = "  ")
    {
        self.isPrettyPrint = isPrettyPrint
        self.indentString = indentString
    }
}

public class JSONSerializer {
    public init() {
        self.options = JSONSerializeOptions()
    }
    
    public var options: JSONSerializeOptions
    
    public func serialize(_ json: JSON) -> Data {
        let s = _Serializer(json: json, options: options)
        s.serialize()
        return s.data
    }
}

internal class _Serializer {
    public let json: JSON
    public let options: JSONSerializeOptions
    public var depth: Int
    public var data: Data
    
    public init(json: JSON,
                options: JSONSerializeOptions)
    {
        self.json = json
        self.options = options
        self.depth = 0
        self.data = Data()
    }
    
    public func serialize() {
        emit(json)
    }
    
    private func emit(_ value: JSON) {
        switch value {
        case .null: emitString("null")
        case .boolean(let b):
            if b {
                emitString("true")
            } else {
                emitString("false")
            }
        case .number(let n):
            emitString(n)
        case .string(let s):
            data.append(.doubleQuote)
            data.append(JSONStringEscape.escape(string: s))
            data.append(.doubleQuote)
        case .array(let a):
            data.append(.leftBracket)
            if a.isEmpty {
                data.append(.rightBracket)
                return
            }
            emitNewLine()
            depth += 1
            for (i, e) in a.enumerated() {
                emitIndent()
                emit(e)
                if i < a.count - 1 {
                    data.append(.comma)
                }
                emitNewLine()
            }
            depth -= 1
            emitIndent()
            data.append(.rightBracket)
        case .object(let o):
            data.append(.leftBrace)
            if o.isEmpty {
                data.append(.rightBrace)
                return
            }
            emitNewLine()
            depth += 1
            for (i, e) in o.enumerated() {
                let (k, v) = e
                emitIndent()
                data.append(.doubleQuote)
                data.append(JSONStringEscape.escape(string: k))
                data.append(.doubleQuote)
                data.append(.colon)
                if options.isPrettyPrint {
                    data.append(.space)
                }
                emit(v)
                if i < o.count - 1 {
                    data.append(.comma)
                }
                emitNewLine()
            }
            depth -= 1
            emitIndent()
            data.append(.rightBrace)
        }
    }
    
    private func emitIndent() {
        guard options.isPrettyPrint else {
            return
        }
        for _ in 0..<depth {
            emitString(options.indentString)
        }
    }
    
    private func emitNewLine() {
        guard options.isPrettyPrint else {
            return
        }
        data.append(.lf)
    }
    
    private func emitString(_ string: String) {
        data.append(contentsOf: string.utf8)
    }
}
