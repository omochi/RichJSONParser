import XCTest
import RichJSONParser

class SerializerTests: XCTestCase {
    
    func testOptions() {
        XCTAssertEqual(JSONSerializeOptions(),
                       JSONSerializeOptions(isPrettyPrint: true, indentString: "  "))
    }
    
    func test1() {
        XCTAssertEqual(serialize(.array([
            .null,
            .boolean(true),
            .boolean(false),
            .number("1"),
            .string("a"),
            .array([]),
            .object(JSONDictionary())
            ]),
                                 options: JSONSerializeOptions(isPrettyPrint: false)),
                       "[null,true,false,1,\"a\",[],{}]")
        
        XCTAssertEqual(serialize(.array([
            .null,
            .boolean(true),
            .boolean(false),
            .number("1"),
            .string("a"),
            .array([]),
            .object(JSONDictionary())
            ]),
                                 options: JSONSerializeOptions(isPrettyPrint: true,
                                                               indentString: "  ")),
                       """
[
  null,
  true,
  false,
  1,
  "a",
  [],
  {}
]
""")
        
    }
    
    func test2() {
        XCTAssertEqual(serialize(.array([]),
                                 options: JSONSerializeOptions(isPrettyPrint: false)),
                       "[]")
        XCTAssertEqual(serialize(.object(JSONDictionary()),
                                 options: JSONSerializeOptions(isPrettyPrint: false)),
                       "{}")
    }
    
    func test3() {
        let json = JSON.object(JSONDictionary([
            "name": .string("taro"),
            "age": .number("30"),
            "foods": .array([
                .string("apple"), .string("banana")
                ])
            ]))
        
        XCTAssertEqual(serialize(json,
                                 options: JSONSerializeOptions(isPrettyPrint: true, indentString: "  ")),
                       """
{
  "name": "taro",
  "age": 30,
  "foods": [
    "apple",
    "banana"
  ]
}
""")
        
        XCTAssertEqual(serialize(json,
                                 options: JSONSerializeOptions(isPrettyPrint: false)),
                       """
{"name":"taro","age":30,"foods":["apple","banana"]}
""")
    }
    
    func test4() {
        let json = JSON.array([
            .string("""
あ"い
う\\え
""")
            ])
        
        let b = "\\"
        XCTAssertEqual(serialize(json, options: JSONSerializeOptions()),
                        """
[
  "あ\(b)"い\(b)nう\(b)\(b)え"
]
""")
    }

    private func serialize(_ json: JSON, options: JSONSerializeOptions) -> String {
        let s = JSONSerializer()
        s.options = options
        let data = s.serialize(json)
        return String(data: data, encoding: .utf8)!
    }
}
