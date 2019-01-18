import Foundation

internal let nullKeyword = "null"
internal let trueKeyword = "true"
internal let falseKeyword = "false"

public class JSONParser {
    public enum Error : Swift.Error, CustomStringConvertible {
        case unexceptedEnd(SourceLocation)
        case invalidToken(JSONToken)
        
        public var description: String {
            switch self {
            case .unexceptedEnd(let loc):
                return "unexcepted end at \(loc)"
            case .invalidToken(let token):
                return "invalid token (\(token))"
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
    
    private func parseValue() throws -> ParsedJSON {
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
        default:
            fatalError()//TODO
        }
    }
}
