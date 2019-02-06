import XCTest
import RichJSONParser

class FastJSONParserTests: XCTestCase {
    func testNull() throws {
        let json = "null"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .null))
    }
    
    func testFalse() throws {
        let json = "false"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .boolean(false)))
    }
    
    func testTrue() throws {
        let json = "true"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .boolean(true)))
    }
    
    func testSpace() throws {
        let json = " \ttrue \t"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(2, 1, 3), value: .boolean(true)))
    }
    
    func testNewLine() throws {
        let json = "\n\r\r\ntrue"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(4, 4, 1), value: .boolean(true)))
    }
    
    func testNumber1() throws {
        let json = "12"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .number("12")))
    }
    
    func testNumber2() throws {
        let json = "0"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .number("0")))
    }
    
    func testNumber3() throws {
        let json = "123.45"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .number("123.45")))
    }
    
    func testNumber4() throws {
        let json = "0.12"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .number("0.12")))
    }
    
    func testNumber5() throws {
        let json = "-1.23e+6"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .number("-1.23e+6")))
    }
    
    func testString1() throws {
        let json = "\"\""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .string("")))
    }
    
    func testString2() throws {
        let json = "\"abc\""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .string("abc")))
    }
    
    func testString3() throws {
        let json = "\"a\\rb\\n\\tc\""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .string("a\rb\n\tc")))
    }
    
    func testUnescape1() throws {
        let json = "\"a\\u3042\\n\\u3044\""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .string("aあ\nい")))
    }
    
    func testEmojiUnescape1() throws {        
        let json = "\"\\uD83D\\uDE00\""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .string("😀")))
    }
    
    func testEmptyArray() throws {
        let json = "[]"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .array([])))
    }

    func testEmptyObject() throws {
        let json = "{}"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .object(JSONDictionary())))
    }
    
    func testArray1() throws {
        let json = "[null, false, true, -12.34e+5, [ ], { }]"
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .array([
            ParsedJSON(location: sloc(1, 1, 2), value: .null),
            ParsedJSON(location: sloc(7, 1, 8), value: .boolean(false)),
            ParsedJSON(location: sloc(14, 1, 15), value: .boolean(true)),
            ParsedJSON(location: sloc(20, 1, 21), value: .number("-12.34e+5")),
            ParsedJSON(location: sloc(31, 1, 32), value: .array([])),
            ParsedJSON(location: sloc(36, 1, 37), value: .object(JSONDictionary()))
            ])))
    }
    
    func testArray2() throws {
        let json = """
[
  true,
  false
]
"""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .array([
            ParsedJSON(location: sloc(4, 2, 3), value: .boolean(true)),
            ParsedJSON(location: sloc(12, 3, 3), value: .boolean(false))
            ])))
    }
    
    func testArray3() throws {
        let json = "[null, true, false, 1, \"\", [], {}]"
        let obj = try parse(json).toJSON()
        XCTAssertEqual(obj, JSON.array([
            .null,
            .boolean(true),
            .boolean(false),
            .number("1"),
            .string(""),
            .array([]),
            .object(JSONDictionary())]))
    }
    
    func testArray4() throws {
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
    
    func testArrayTailComma() throws {
        let json = """
[
  true,
  false,
]
"""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .array([
            ParsedJSON(location: sloc(4, 2, 3), value: .boolean(true)),
            ParsedJSON(location: sloc(12, 3, 3), value: .boolean(false))
            ])))
    }

    func testArrayNest() throws {
        let json = """
[
  [ 1 ]
]
"""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .array([
            ParsedJSON(location: sloc(4, 2, 3), value: .array([
                ParsedJSON(location: sloc(6, 2, 5), value: .number("1"))
                ])),
            ])))
    }
    
    func testObject1() throws {
        let json = """
{
  "k1": "v1",
  "k2": "v2"
}
"""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .object(JSONDictionary([
            "k1": ParsedJSON(location: sloc(10, 2, 9), value: .string("v1")),
            "k2": ParsedJSON(location: sloc(24, 3, 9), value: .string("v2"))
            ]))))
    }
    
    func testObject2() throws {
        XCTAssertEqual(try parse("{}").toJSON(),
                       JSON.object(JSONDictionary()))
        XCTAssertEqual(try parse("""
{ "a": 1 }
""").toJSON(),
                       JSON.object(JSONDictionary([
                        "a": .number("1")
                        ])))
        XCTAssertEqual(try parse("""
{ "a": 1, }
""").toJSON(),
                       JSON.object(JSONDictionary([
                        "a": .number("1")
                        ])))
        XCTAssertEqual(try parse("""
{
  "a": 1,
  "b": 2
}
""").toJSON(),
                       JSON.object(JSONDictionary([
                        "a": .number("1"),
                        "b": .number("2"),
                        ])))
        XCTAssertEqual(try parse("""
{
  "a": 1,
  "b": 2,
}
""").toJSON(),
                       JSON.object(JSONDictionary([
                        "a": .number("1"),
                        "b": .number("2"),
                        ])))
    }
    
    func testObject3() throws {
        let json = """
{
  "name": "taro",
  "age": 30,
  "foods": ["apple", "banana"]
}
"""
        XCTAssertEqual(try parse(json),
                       ParsedJSON(location: sloc(0, 1, 1),
                                  value: .object(JSONDictionary([
                                    "name": ParsedJSON(location: sloc(12, 2, 11),
                                                       value: .string("taro")),
                                    "age": ParsedJSON(location: sloc(29, 3, 10),
                                                      value: .number("30")),
                                    "foods": ParsedJSON(location: sloc(44, 4, 12),
                                                        value: .array([
                                                            ParsedJSON(location: sloc(45, 4, 13),
                                                                       value: .string("apple")),
                                                            ParsedJSON(location: sloc(54, 4, 22),
                                                                       value: .string("banana"))
                                                            ])),
                                    ]))))
    }
    
    func testObjectNest() throws {
        let json = """
{
  "k1": [ "v2" ],
  "k2": {
    "k3": "v3"
  }
}
"""
        
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .object(JSONDictionary([
            "k1": ParsedJSON(location: sloc(10, 2, 9), value: .array([
                ParsedJSON(location: sloc(12, 2, 11), value: .string("v2"))
                ])),
            "k2": ParsedJSON(location: sloc(28, 3, 9), value: .object(JSONDictionary([
                "k3": ParsedJSON(location: sloc(40, 4, 11), value: .string("v3"))
                ])))
            ]))))
    }
    
    func testLineComment() throws {
        let json = """
[
  1, // a
// b
  2 // c
]
"""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(0, 1, 1), value: .array([
            ParsedJSON(location: sloc(4, 2, 3), value: .number("1")),
            ParsedJSON(location: sloc(19, 4, 3), value: .number("2"))
            ])))
    }
    
    func testBlockComment() throws {
        let json = """
/*
aaa
*/
1
"""
        let obj = try parse(json)
        XCTAssertEqual(obj, ParsedJSON(location: sloc(10, 4, 1), value: .number("1")))
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
                       JSON.object(JSONDictionary([
                        "name": .string("taro"),
                        "foods": .array([.number("1")])
                        ])))
    }
    
    private func parse(_ json: String) throws -> ParsedJSON {
        let data = json.data(using: .utf8)!
        let parser = FastJSONParser(data: data, file: nil)
        return try parser.parse()
    }
}
