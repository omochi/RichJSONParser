import XCTest
import RichJSONParser

class UTF8ReaderTests: XCTestCase {
    func test1() throws {
        let string = "a\rb\nc\r\nd"
        let data = string.data(using: .utf8)!
        let reader = try UTF8Reader(data: data)
        
        let loc0 = reader.location
        XCTAssertEqual(loc0, SourceLocationLite(offset: 0, line: 1, columnInByte: 1))
        XCTAssertEqual(reader.char, Unicode.Scalar("a")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("a")!)
        
        let loc1 = reader.location
        XCTAssertEqual(loc1, SourceLocationLite(offset: 1, line: 1, columnInByte: 2))
        XCTAssertEqual(reader.char, Unicode.Scalar("\r")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\r")!)
        
        let loc2 = reader.location
        XCTAssertEqual(loc2, SourceLocationLite(offset: 2, line: 2, columnInByte: 1))
        XCTAssertEqual(reader.char, Unicode.Scalar("b")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("b")!)
      
        let loc3 = reader.location
        XCTAssertEqual(loc3, SourceLocationLite(offset: 3, line: 2, columnInByte: 2))
        XCTAssertEqual(reader.char, Unicode.Scalar("\n")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\n")!)
        
        let loc4 = reader.location
        XCTAssertEqual(loc4, SourceLocationLite(offset: 4, line: 3, columnInByte: 1))
        XCTAssertEqual(reader.char, Unicode.Scalar("c")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("c")!)
        
        let loc5 = reader.location
        XCTAssertEqual(loc5, SourceLocationLite(offset: 5, line: 3, columnInByte: 2))
        XCTAssertEqual(reader.char, Unicode.Scalar("\r")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\r")!)
        
        let loc6 = reader.location
        XCTAssertEqual(loc6, SourceLocationLite(offset: 6, line: 3, columnInByte: 3))
        XCTAssertEqual(reader.char, Unicode.Scalar("\n")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\n")!)
        
        let loc7 = reader.location
        XCTAssertEqual(loc7, SourceLocationLite(offset: 7, line: 4, columnInByte: 1))
        XCTAssertEqual(reader.char, Unicode.Scalar("d")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("d")!)
        
        let loc8 = reader.location
        XCTAssertEqual(loc8, SourceLocationLite(offset: 8, line: 4, columnInByte: 2))
        XCTAssertEqual(reader.char, nil)
        XCTAssertEqual(try reader.read(), nil)
        
        let loc9 = reader.location
        XCTAssertEqual(loc9, SourceLocationLite(offset: 8, line: 4, columnInByte: 2))
        XCTAssertEqual(reader.char, nil)
        XCTAssertEqual(try reader.read(), nil)
        
        try reader.seek(to: loc1)
        XCTAssertEqual(reader.location, loc1)
        XCTAssertEqual(reader.char, Unicode.Scalar("\r")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\r")!)
        
        try reader.seek(to: loc3)
        XCTAssertEqual(reader.location, loc3)
        XCTAssertEqual(reader.char, Unicode.Scalar("\n")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\n")!)
        
        try reader.seek(to: loc5)
        XCTAssertEqual(reader.location, loc5)
        XCTAssertEqual(reader.char, Unicode.Scalar("\r")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\r")!)
        
        try reader.seek(to: loc6)
        XCTAssertEqual(reader.location, loc6)
        XCTAssertEqual(reader.char, Unicode.Scalar("\n")!)
        XCTAssertEqual(try reader.read(), Unicode.Scalar("\n")!)
    }


}
