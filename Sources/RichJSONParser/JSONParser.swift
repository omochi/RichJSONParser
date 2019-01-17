import Foundation

internal let nullKeywordData = "null".data(using: .utf8)!
internal let trueKeywordData = "true".data(using: .utf8)!
internal let falseKeywordData = "false".data(using: .utf8)!

public class JSONParser {
    public enum Error : Swift.Error {
        case unexceptedEnd(JSONToken)
        case invalidToken(JSONToken)
        case utf8DecodeError(SourceLocation)
        case stringUnescapeError(SourceLocation, Swift.Error)
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
            throw Error.unexceptedEnd(token)
        case .keyword:
            let data = tokenizer.data(of: token)
            if data == nullKeywordData {
                return ParsedJSON(location: token.location,
                                  value: .null)
            } else if data == falseKeywordData {
                return ParsedJSON(location: token.location,
                                  value: .boolean(false))
            } else if data == trueKeywordData {
                return ParsedJSON(location: token.location,
                                  value: .boolean(true))
            } else {
                throw Error.invalidToken(token)
            }
        case .number:
            let data = tokenizer.data(of: token)
            let str = try decodeUTF8(data: data, location: token.location)
            return ParsedJSON(location: token.location, value: .number(str))
        case .string:
            var data = tokenizer.data(of: token)
            
            // trim double quote
            let start = data.index(after: data.startIndex)
            let end = data.index(before: data.endIndex)
            data = data[start..<end]
            
            let stringData = try unescape(data: data, location: token.location.addingColumn(length: 1))
            let str = try decodeUTF8(data: stringData, location: token.location)
            return ParsedJSON(location: token.location, value: .string(str))
        default:
            fatalError()//TODO
        }
    }
    
    private func unescape(data: Data, location: SourceLocation) throws -> Data {
        do {
            return try JSONStringEscape.unescape(data: data)
        } catch {
            throw Error.stringUnescapeError(location, error)
        }
    }
    
    private func decodeUTF8(data: Data, location: SourceLocation) throws -> String {
        guard let str = String(data: data, encoding: .utf8) else {
            throw Error.utf8DecodeError(location)
        }
        return str
    }
}
