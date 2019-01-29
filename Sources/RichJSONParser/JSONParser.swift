import Foundation
import OrderedDictionary

internal let nullKeyword = "null"
internal let trueKeyword = "true"
internal let falseKeyword = "false"

public class JSONParser {
    public enum Error : LocalizedError, CustomStringConvertible {
        case unexceptedEnd(SourceLocation)
        case invalidToken(JSONToken)
        case unexceptedToken(JSONToken, expected: String)
        case keyNotString(SourceLocation)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .unexceptedEnd(let loc):
                return "unexcepted end at \(loc)"
            case .invalidToken(let token):
                return "invalid token (\(token))"
            case .unexceptedToken(let token, let exp):
                return "unexcepted token (\(token)), expected (\(exp))"
            case .keyNotString(let loc):
                return "object key is not string at \(loc)"
            }
        }
    }
    
    public init(data: Data) {
        self.tokenizer = JSONTokenizer(data: data)
    }
    
    private let tokenizer: JSONTokenizer
    
    public func parse() throws -> ParsedJSON {
        return try parseValue()
    }
    
    public func parseValue() throws -> ParsedJSON {
        let start = tokenizer.location
        let token = try tokenizer.read()
        
        switch token.kind {
        case .end:
            throw Error.unexceptedEnd(token.location)
        case .keyword:
            let string = token.string!
            if string == nullKeyword {
                return ParsedJSON(location: token.location, value: .null)
            } else if string == falseKeyword {
                return ParsedJSON(location: token.location, value: .boolean(false))
            } else if string == trueKeyword {
                return ParsedJSON(location: token.location, value: .boolean(true))
            } else {
                throw Error.invalidToken(token)
            }
        case .number:
            let string = token.string!
            return ParsedJSON(location: token.location, value: .number(string))
        case .string:
            let string = token.string!
            return ParsedJSON(location: token.location, value: .string(string))
        case .leftBracket:
            tokenizer.location = start
            return try parseArray()
        case .leftBrace:
            tokenizer.location = start
            return try parseObject()
        default:
            throw Error.invalidToken(token)
        }
    }
    
    public func parseArray() throws -> ParsedJSON {
        var result = [ParsedJSON]()
        
        let t0 = try tokenizer.read()
        guard t0.kind == .leftBracket else {
            throw Error.unexceptedToken(t0, expected: "[")
        }
        
        while true {
            let loc = tokenizer.location
            let t1 = try tokenizer.read()
            if t1.kind == .rightBracket {
                break
            }
            tokenizer.location = loc

            let e = try parseValue()
            result.append(e)
            
            let t2 = try tokenizer.read()
            
            if t2.kind == .comma {
                continue
            } else if t2.kind == .rightBracket {
                break
            } else {
                throw Error.unexceptedToken(t0, expected: ", or ]")
            }
        }
        
        return ParsedJSON(location: t0.location,
                          value: .array(result))
    }
    
    public func parseObject() throws -> ParsedJSON {
        var result = OrderedDictionary<String, ParsedJSON>()
        
        let t0 = try tokenizer.read()
        guard t0.kind == .leftBrace else {
            throw Error.unexceptedToken(t0, expected: "{")
        }
        
        while true {
            let loc = tokenizer.location
            let t1 = try tokenizer.read()
            if t1.kind == .rightBrace {
                break
            }
            tokenizer.location = loc
            
            let k = try parseValue()
            
            guard case .string(let keyString) = k.value else {
                throw Error.keyNotString(k.location)
            }
            
            let t2 = try tokenizer.read()
            if t2.kind == .colon {
                //
            } else {
                throw Error.unexceptedToken(t2, expected: ":")
            }
            
            let v = try parseValue()
            result[keyString] = v
            
            let t3 = try tokenizer.read()
            if t3.kind == .comma {
                continue
            } else if t3.kind == .rightBrace {
                break
            } else {
                throw Error.unexceptedToken(t3, expected: ", or }")
            }
        }
        
        return ParsedJSON(location: t0.location,
                          value: .object(result))
    }
}
