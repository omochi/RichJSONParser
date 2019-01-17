import XCTest
import RichJSONParser

class TokenizerTests : XCTestCase {
    func testLineComment1() throws {
        let str = """
1
// aaa
2
"""
        try testTokens(string: str,
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 1, kind: .number),
                        JSONToken(location: SourceLocation(offset: 1,
                                                           line: 1,
                                                           columnInByte: 2),
                                  length: 1, kind: .newLine),
                        JSONToken(location: SourceLocation(offset: 2,
                                                           line: 2,
                                                           columnInByte: 1),
                                  length: 6,
                                  kind: .lineComment),
                        JSONToken(location: SourceLocation(offset: 8,
                                                           line: 2,
                                                           columnInByte: 7),
                                  length: 1,
                                  kind: .newLine),
                        JSONToken(location: SourceLocation(offset: 9,
                                                           line: 3,
                                                           columnInByte: 1),
                                  length: 1,
                                  kind: .number)
            ])
    }
    
    func testBlockComment1() throws {
        let str = """
/*
aaa
*/
1
"""
        try testTokens(string: str,
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 9, kind: .blockComment),
                        JSONToken(location: SourceLocation(offset: 9,
                                                           line: 3,
                                                           columnInByte: 3),
                                  length: 1, kind: .newLine),
                        JSONToken(location: SourceLocation(offset: 10,
                                                           line: 4,
                                                           columnInByte: 1),
                                  length: 1,
                                  kind: .number)
            ])
    }
    
    func testNumber1() throws {
        try testTokens(string: "123 456",
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 3,
                                  kind: .number),
                        JSONToken(location: SourceLocation(offset: 3,
                                                           line: 1,
                                                           columnInByte: 4),
                                  length: 1,
                                  kind: .whiteSpace),
                        JSONToken(location: SourceLocation(offset: 4,
                                                           line: 1,
                                                           columnInByte: 5),
                                  length: 3,
                                  kind: .number)
            ])

    }
    
    func testNumber2() throws {
        try testTokens(string: "-0.123",
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 6,
                                  kind: .number)
            ])
    }
    
    func testNumber3() throws {
        try testTokens(string: "1.0e+6",
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 6,
                                  kind: .number)
            ])
    }
    
    func testString1() throws {
        let str = """
"hello"
"""
        try testTokens(string: str,
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 7,
                                  kind: .string)
            ])
    }
    
    func testNull1() throws {
        let str = """
null
"""
        try testTokens(string: str,
                       expected: [
                        JSONToken(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  length: 4,
                                  kind: .keyword)
            ])
    }
    
    func testTokens(string: String,
                    expected: [JSONToken],
                    file: StaticString = #file,
                    line: UInt = #line) throws
    {
        let data = string.data(using: .utf8)!
        let tk = JSONTokenizer(data: data)
        var actual = [JSONToken]()
        while true {
            let token = try tk.read()
            if case .end = token.kind {
                break
            }
            actual.append(token)
        }
        XCTAssertEqual(actual, expected)
    }
}
