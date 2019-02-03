import Foundation
import OrderedDictionary

internal let nullKeyword = "null"
internal let trueKeyword = "true"
internal let falseKeyword = "false"

public class JSONParser {
    public enum Error : LocalizedError, CustomStringConvertible {
        case invalidToken(JSONToken)
        case unexceptedToken(JSONToken, expected: String)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .invalidToken(let token):
                return "invalid token (\(token))"
            case .unexceptedToken(let token, let exp):
                return "unexcepted token (\(token)), expected (\(exp))"
            }
        }
    }
    
    private enum State {
        case start
        case complete(ParsedJSON)
        case array(Array)
        case object(Object)
        
        struct Array {
            var array: [ParsedJSON]
            var location: SourceLocation
        }
        
        struct Object {
            var object: OrderedDictionary<String, ParsedJSON>
            var location: SourceLocation
            var key: String?
        }
    }
    
    private struct Token {
        enum Value {
            case end
            case keyword(ParsedJSON)
            case number(ParsedJSON)
            case string(ParsedJSON)
            case leftBracket
            case rightBracket
            case leftBrace
            case rightBrace
        }
        
        var value: Value
        var token: JSONToken
    }
    
    public init(data: Data, file: URL? = nil) {
        self.tokenizer = JSONTokenizer(data: data, file: file)
        self.stack = [State.start]
    }
    
    private let tokenizer: JSONTokenizer
    private var stack: [State]
    private var state: State {
        get { return stack[stack.count - 1] }
        set { stack[stack.count - 1] = newValue }
    }
    
    public func parse() throws -> ParsedJSON {
        while true {
            switch state {
            case .complete(let x):
                return x
            case .start:
                try processStart()
            case .array(let state):
                try processArray(state)
            case .object(let state):
                try processObject(state)
            }
        }
    }
    
    private func processStart() throws {
        let token = try readToken()
        switch token.value {
        case .keyword(let x),
             .number(let x),
             .string(let x):
            state = .complete(x)
        case .leftBracket:
            state = .array(State.Array(array: [], location: token.token.location))
        case .leftBrace:
            state = .object(State.Object(object: OrderedDictionary(),
                                         location: token.token.location,
                                         key: nil))
        default: throw Error.invalidToken(token.token)
        }
    }
        
    private func processArray(_ state: State.Array) throws {
        let token = try readToken()
        switch token.value {
        case .keyword(let x),
             .number(let x),
             .string(let x):
            try addArrayItem(state: state, value: x)
        case .leftBracket:
            stack.append(.array(State.Array(array: [], location: token.token.location)))
        case .leftBrace:
            stack.append(.object(State.Object(object: OrderedDictionary(),
                                              location: token.token.location,
                                              key: nil)))
        case .rightBracket:
            try emitValue(ParsedJSON(location: state.location,
                                     value: .array(state.array)))
        default: throw Error.invalidToken(token.token)
        }
    }

    private func processObject(_ state: State.Object) throws {
        var state = state
        
        let keyToken = try tokenizer.read()
        switch keyToken.kind {
        case .string:
            state.key = keyToken.string!
            self.state = .object(state)
        case .rightBrace:
            try emitValue(ParsedJSON(location: state.location,
                                     value: .object(state.object)))
            return
        default: throw Error.unexceptedToken(keyToken, expected: "key string")
        }
        
        try consumeColon()
        
        let token = try readToken()
        switch token.value {
        case .keyword(let x),
             .number(let x),
             .string(let x):
            try addObjectItem(state: state, value: x)
        case .leftBracket:
            stack.append(.array(State.Array(array: [], location: token.token.location)))
        case .leftBrace:
            stack.append(.object(State.Object(object: OrderedDictionary(),
                                              location: token.token.location,
                                              key: nil)))
        default: throw Error.invalidToken(token.token)
        }
    }
    
    private func emitValue(_ value: ParsedJSON) throws {
        if stack.count == 1 {
            state = .complete(value)
            return
        }
        
        stack.removeLast()
        
        switch state {
        case .array(let state):
            try addArrayItem(state: state, value: value)
        case .object(let state):
            try addObjectItem(state: state, value: value)
        default: fatalError("invalid state")
        }
    }
    
    private func addArrayItem(state: State.Array,
                              value: ParsedJSON) throws
    {
        var state = state
        state.array.append(value)
        self.state = .array(state)
        
        try mayConsumeComma()
    }
    
    private func addObjectItem(state: State.Object,
                               value: ParsedJSON) throws
    {
        var state = state
        let key = state.key!
        state.object[key] = value
        self.state = .object(state)
        
        try mayConsumeComma()
    }
    
    private func mayConsumeComma() throws {
        let location = tokenizer.location
        let token = try tokenizer.read()
        switch token.kind {
        case .comma, .end: break
        default:
            tokenizer.location = location
        }
    }
    
    private func consumeColon() throws {
        let token = try tokenizer.read()
        switch token.kind {
        case .colon: break
        default:
            throw Error.unexceptedToken(token, expected: "colon")
        }
    }
    
    private func readToken() throws -> Token {
        let token = try tokenizer.read()
        switch token.kind {
        case .keyword:
            let value = try parseKeyword(token: token)
            return Token(value: .keyword(value), token: token)
        case .number:
            let value = ParsedJSON(location: token.location, value: .number(token.string!))
            return Token(value: .number(value), token: token)
        case .string:
            let value = ParsedJSON(location: token.location, value: .string(token.string!))
            return Token(value: .string(value), token: token)
        case .leftBracket: return Token(value: .leftBracket, token: token)
        case .rightBracket: return Token(value: .rightBracket, token: token)
        case .leftBrace: return Token(value: .leftBrace, token: token)
        case .rightBrace: return Token(value: .rightBrace, token: token)
        default: throw Error.invalidToken(token)
        }
    }
    
    private func parseKeyword(token: JSONToken) throws -> ParsedJSON {
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
    }
}
