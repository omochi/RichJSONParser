import XCTest
import RichJSONParser
import Foundation

class BenchmarkTests: XCTestCase {

    func testParse() throws {
        let file = Resources.shared.path("first-mate-tests.json")
        let data = try Data(contentsOf: file)
        self.measure {
            do {
                for _ in 0..<100 {
                    let parser = JSONParser(data: data, file: file)
                    _ = try parser.parse()
                }
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    func testParseFoundationX100() throws {
        let file = Resources.shared.path("first-mate-tests.json")
        let data = try Data(contentsOf: file)

        self.measure {
            do {
                for _ in 0..<100 {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                }
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
}
