import XCTest
import RichJSONParser
import OrderedDictionary

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
        
        XCTAssertEqual(o, ParsedJSON(location: SourceLocation(offset: 2,
                                                              line: 1,
                                                              columnInByte: 3),
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
    
    func test1() throws {
        let json = """
{
  "name": "taro",
  "age": 30,
  "foods": ["apple", "banana"]
}
"""
        XCTAssertEqual(try parse(json),
                       ParsedJSON(location: SourceLocation(offset: 0,
                                                           line: 1,
                                                           columnInByte: 1),
                                  value: .object(OrderedDictionary([
                                    "name": ParsedJSON(location: SourceLocation(offset: 12,
                                                                                line: 2,
                                                                                columnInByte: 11),
                                                       value: .string("taro")),
                                    "age": ParsedJSON(location: SourceLocation(offset: 29,
                                                                               line: 3,
                                                                               columnInByte: 10),
                                                      value: .number("30")),
                                    "foods": ParsedJSON(location: SourceLocation(offset: 44,
                                                                                 line: 4,
                                                                                 columnInByte: 12),
                                                        value: .array([
                                                            ParsedJSON(location: SourceLocation(offset: 45,
                                                                                                line: 4,
                                                                                                columnInByte: 13),
                                                                       value: .string("apple")),
                                                            ParsedJSON(location: SourceLocation(offset: 54,
                                                                                                line: 4,
                                                                                                columnInByte: 22),
                                                                       value: .string("banana"))
                                                            ])),
                        ]))))
        
    }

    private func parse(_ json: String) throws -> ParsedJSON {
        let data = json.data(using: .utf8)!
        let p = JSONParser(data: data)
        return try p.parse()
    }

}
