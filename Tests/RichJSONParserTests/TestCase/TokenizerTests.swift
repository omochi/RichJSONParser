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
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 1, kind: .number, string: "1"),
                        JSONToken(location: sloc(1, 1, 2),
                                  length: 1, kind: .newLine, string: nil),
                        JSONToken(location: sloc(2, 2, 1),
                                  length: 6, kind: .lineComment, string: nil),
                        JSONToken(location: sloc(8, 2, 7),
                                  length: 1, kind: .newLine, string: nil),
                        JSONToken(location: sloc(9, 3, 1),
                                  length: 1, kind: .number, string: "2")
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
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 9, kind: .blockComment, string: nil),
                        JSONToken(location: sloc(9, 3, 3),
                                  length: 1, kind: .newLine, string: nil),
                        JSONToken(location: sloc(10, 4, 1),
                                  length: 1, kind: .number, string: "1")
            ])
    }
    
    func testNumber1() throws {
        try testTokens(string: "123 456",
                       expected: [
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 3, kind: .number, string: "123"),
                        JSONToken(location: sloc(3, 1, 4),
                                  length: 1, kind: .whiteSpace, string: nil),
                        JSONToken(location: sloc(4, 1, 5),
                                  length: 3, kind: .number, string: "456")
            ])

    }
    
    func testNumber2() throws {
        try testTokens(string: "-0.123",
                       expected: [
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 6, kind: .number, string: "-0.123")
            ])
    }
    
    func testNumber3() throws {
        try testTokens(string: "1.0e+6",
                       expected: [
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 6, kind: .number, string: "1.0e+6")
            ])
    }
    
    func testString1() throws {
        let str = """
"hello"
"""
        try testTokens(string: str,
                       expected: [
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 7, kind: .string, string: "hello")
            ])
    }
    
    func testNull1() throws {
        let str = """
null
"""
        try testTokens(string: str,
                       expected: [
                        JSONToken(location: sloc(0, 1, 1),
                                  length: 4, kind: .keyword, string: "null")
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
            let token = try tk.readRaw()
            if case .end = token.kind {
                break
            }
            actual.append(token)
        }
        XCTAssertEqual(actual, expected)
    }
}
