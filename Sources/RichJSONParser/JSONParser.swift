import Foundation

internal let nullKeyword = "null"
internal let trueKeyword = "true"
internal let falseKeyword = "false"

public class JSONParser {
    public enum Error : LocalizedError, CustomStringConvertible {
        case invalidToken(JSONToken, file: URL?)
        case unexceptedToken(JSONToken, expected: String, file: URL?)
        
        public var errorDescription: String? { return description }
        
        public var description: String {
            switch self {
            case .invalidToken(let token, let file):
                var d = "invalid token \(token)"
                d += file.map { ", file: \($0.path)" } ?? ""
                return d
            case .unexceptedToken(let token, let exp, let file):
                var d = "unexcepted token \(token), expected: \(exp)"
                d += file.map { ", file: \($0.path)" } ?? ""
                return d
            }
        }
    }
    
    private enum State {
        case start
        case complete(ParsedJSON)
        case array(Array)
        case object(Object)
        
        final class Array {
            var array: [ParsedJSON]
            var location: SourceLocationLite
            
            init(array: [ParsedJSON],
                 location: SourceLocationLite)
            {
                self.array = array
                self.location = location
            }
        }
        
        final class Object {
            var object: JSONDictionary<ParsedJSON>
            var location: SourceLocationLite
            var key: String?
            
            init(object: JSONDictionary<ParsedJSON>,
                 location: SourceLocationLite)
            {
                self.object = object
                self.location = location
            }
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
    
    public init(data: Data, file: URL? = nil) throws {
        self.tokenizer = try JSONTokenizer(data: data, file: file)
        self.stack = [State.start]
    }
    
    public var file: URL? {
        return tokenizer.file
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
            self.state = .complete(x)
        case .leftBracket:
            stack.removeLast()
            pushArray(token: token)
        case .leftBrace:
            stack.removeLast()
            pushObject(token: token)
        default: throw Error.invalidToken(token.token, file: file)
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
            pushArray(token: token)
        case .leftBrace:
            pushObject(token: token)
        case .rightBracket:
            try emitValue(ParsedJSON(location: state.location,
                                     value: .array(state.array)))
        default: throw Error.invalidToken(token.token, file: file)
        }
    }

    private func processObject(_ state: State.Object) throws {
        let keyToken = try tokenizer.read()
        switch keyToken.kind {
        case .string:
            state.key = keyToken.string!
        case .rightBrace:
            try emitValue(ParsedJSON(location: state.location,
                                     value: .object(state.object)))
            return
        default: throw Error.unexceptedToken(keyToken, expected: "key string", file: file)
        }
        
        try consumeColon()
        
        let token = try readToken()
        switch token.value {
        case .keyword(let x),
             .number(let x),
             .string(let x):
            try addObjectItem(state: state, value: x)
        case .leftBracket:
            pushArray(token: token)
        case .leftBrace:
            pushObject(token: token)
        default: throw Error.invalidToken(token.token, file: file)
        }
    }
    
    private func emitValue(_ value: ParsedJSON) throws {
        if stack.count == 1 {
            self.state = .complete(value)
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
    
    private func pushArray(token: Token) {
        let state = State.Array(array: [],
                                location: token.token.location)
        stack.append(.array(state))
    }
    
    private func pushObject(token: Token) {
        let state = State.Object(object: JSONDictionary(),
                                 location: token.token.location)
        stack.append(.object(state))
    }
    
    private func addArrayItem(state: State.Array,
                              value: ParsedJSON) throws
    {
        state.array.append(value)

        try mayConsumeComma()
    }
    
    private func addObjectItem(state: State.Object,
                               value: ParsedJSON) throws
    {
        let key = state.key!
        
        state.object[key] = value
        
        try mayConsumeComma()
    }
    
    private func mayConsumeComma() throws {
        let location = tokenizer.location
        let token = try tokenizer.read()
        switch token.kind {
        case .comma, .end: break
        default:
            try tokenizer.seek(to: location)
        }
    }
    
    private func consumeColon() throws {
        let token = try tokenizer.read()
        switch token.kind {
        case .colon: break
        default:
            throw Error.unexceptedToken(token, expected: "colon", file: file)
        }
    }
    
    private func readToken() throws -> Token {
        let token = try tokenizer.read()
        switch token.kind {
        case .keyword:
            let value = try parseKeyword(token: token)
            return Token(value: .keyword(value), token: token)
        case .number:
            let value = ParsedJSON(location: token.location,
                                   value: .number(token.string!))
            return Token(value: .number(value), token: token)
        case .string:
            let value = ParsedJSON(location: token.location,
                                   value: .string(token.string!))
            return Token(value: .string(value), token: token)
        case .leftBracket: return Token(value: .leftBracket, token: token)
        case .rightBracket: return Token(value: .rightBracket, token: token)
        case .leftBrace: return Token(value: .leftBrace, token: token)
        case .rightBrace: return Token(value: .rightBrace, token: token)
        default: throw Error.invalidToken(token, file: file)
        }
    }
    
    private func parseKeyword(token: JSONToken) throws -> ParsedJSON {
        let string = token.string!
        if string == nullKeyword {
            return ParsedJSON(location: token.location,
                              value: .null)
        } else if string == falseKeyword {
            return ParsedJSON(location: token.location,
                              value: .boolean(false))
        } else if string == trueKeyword {
            return ParsedJSON(location: token.location,
                              value: .boolean(true))
        } else {
            throw Error.invalidToken(token, file: file)
        }
    }
}
