import XCTest
import RichJSONParser

class StringEscapeTests: XCTestCase {
    func testUnescape1() throws {
        let a = "a\\u3042\\n\\u3044"
        let b = try unescape(string: a)
        XCTAssertEqual(b, "aあ\nい")
    }
    
    func testUnescape2() throws {
        let a = "\"a\\u3042\\n\\u3044\"b"
        let b = try unescape(string: a)
        XCTAssertEqual(b, "aあ\nい")
    }
    
    func testEscape1() throws {
        let a = "aあ\nい"
        let b = try escape(string: a)
        XCTAssertEqual(b, "a\\u3042\\n\\u3044")
    }
    
    func unescape(string: String) throws -> String {
        let data = string.data(using: .utf8)!
        return try JSONStringEscape.unescape(data: data)
    }
    
    func escape(string: String) throws -> String {
        let data = try JSONStringEscape.escape(string: string)
        return String(data: data, encoding: .utf8)!
    }
}
