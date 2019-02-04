import XCTest
import RichJSONParser
import OrderedDictionary

internal func sloc(_ offset: Int,
                   _ line: Int,
                   _ col: Int) -> SourceLocationLite
{
    return SourceLocationLite(offset: offset,
                              line: line,
                              columnInByte: col)
}

internal func sloc2(_ offset: Int,
                    _ line: Int,
                    _ col: Int) -> SourceLocation
{
    return SourceLocation(offset: offset,
                          line: line,
                          columnInByte: col,
                          file: nil)
}

class ParserTests: XCTestCase {
    func testTypes() throws {
        XCTAssertEqual(try parse("[null, true, false, 1, \"\", [], {}]").toJSON(),
                       JSON.array([
                        .null,
                        .boolean(true),
                        .boolean(false),
                        .number("1"),
                        .string(""),
                        .array([]),
                        .object(OrderedDictionary())]))
       
    }
    
    func testNumber1() throws {
        let o = try parse("  123  ")
        
        XCTAssertEqual(o, ParsedJSON(location: sloc2(2, 1, 3),
                                     value: .number("123")))
    }
    
    func testArray1() throws {
        XCTAssertEqual(try parse("[]").toJSON(),
                       JSON.array([]))
        
        XCTAssertEqual(try parse("[1]").toJSON(),
                       JSON.array([
                        .number("1")
                        ]))
        
        XCTAssertEqual(try parse("[1,]").toJSON(),
                       JSON.array([
                        .number("1")
                        ]))
        
        XCTAssertEqual(try parse("[1, 2]").toJSON(),
                       JSON.array([
                        .number("1"),
                        .number("2")]))
        
        XCTAssertEqual(try parse("[1, 2,]").toJSON(),
                       JSON.array([
                        .number("1"),
                        .number("2")]))
    }
    
    func testObject1() throws {
        XCTAssertEqual(try parse("{}").toJSON(),
                       JSON.object(OrderedDictionary()))
        XCTAssertEqual(try parse("""
{ "a": 1 }
""").toJSON(),
                       JSON.object(OrderedDictionary([
                        "a": .number("1")
                        ])))
        XCTAssertEqual(try parse("""
{ "a": 1, }
""").toJSON(),
                       JSON.object(OrderedDictionary([
                        "a": .number("1")
                        ])))
        XCTAssertEqual(try parse("""
{
  "a": 1,
  "b": 2
}
""").toJSON(),
                       JSON.object(OrderedDictionary([
                        "a": .number("1"),
                        "b": .number("2"),
                        ])))
        XCTAssertEqual(try parse("""
{
  "a": 1,
  "b": 2,
}
""").toJSON(),
                       JSON.object(OrderedDictionary([
                        "a": .number("1"),
                        "b": .number("2"),
                        ])))
    }
    
    func testComment1() throws {
        let json = """
{
  "name": "taro", // ケツカンマ
  /* ブロックコメント
  "age": 30
  */
  "foods": [1,] // ケツカンマ
}
"""
        XCTAssertEqual(try parse(json).toJSON(),
                       JSON.object(OrderedDictionary([
                        "name": .string("taro"),
                        "foods": .array([.number("1")])
                        ])))
        
    }
    
    func test1() throws {
        let json = """
{
  "name": "taro",
  "age": 30,
  "foods": ["apple", "banana"]
}
"""
        XCTAssertEqual(try parse(json),
                       ParsedJSON(location: sloc2(0, 1, 1),
                                  value: .object(OrderedDictionary([
                                    "name": ParsedJSON(location: sloc2(12, 2, 11),
                                                       value: .string("taro")),
                                    "age": ParsedJSON(location: sloc2(29, 3, 10),
                                                      value: .number("30")),
                                    "foods": ParsedJSON(location: sloc2(44, 4, 12),
                                                        value: .array([
                                                            ParsedJSON(location: sloc2(45, 4, 13),
                                                                       value: .string("apple")),
                                                            ParsedJSON(location: sloc2(54, 4, 22),
                                                                       value: .string("banana"))
                                                            ])),
                        ]))))
    }

    private func parse(_ json: String) throws -> ParsedJSON {
        let data = json.data(using: .utf8)!
        let p = try JSONParser(data: data)
        return try p.parse()
    }

}
