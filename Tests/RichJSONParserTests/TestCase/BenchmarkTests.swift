import XCTest
import RichJSONParser
import Foundation

class BenchmarkTests: XCTestCase {

    func testParse() throws {
        myPerformanceTest { (measure) in
            let file = Resources.shared.path("first-mate-tests.json")
            let data = try! Data(contentsOf: file)
            
            for _ in 0..<4000 {
                measure {
                    let parser = try! JSONParser(data: data, file: file)
                    _ = try! parser.parse()
                }
            }
        }
    }
    
    func testFastParse() throws {
        myPerformanceTest { (measure) in
            let file = Resources.shared.path("first-mate-tests.json")
            let data = try! Data(contentsOf: file)

            for _ in 0..<4000 {
                measure {
                    autoreleasepool {
                        let parser = FastJSONParser(data: data, file: file)
                        _ = try! parser.parse()
                    }
                }
            }
        }
    }
    
    func testParseFoundationX100() throws {
        myPerformanceTest { (measure) in
            let file = Resources.shared.path("first-mate-tests.json")
            let data = try! Data(contentsOf: file)
            
            for _ in 0..<4000 {
                measure {
                    autoreleasepool {
                        _ = try! JSONSerialization.jsonObject(with: data, options: [])
                    }
                }
            }
        }
    }
    
    func testDataAccess() throws {
        myPerformanceTest { (measure) in
            let file = Resources.shared.path("first-mate-tests.json")
            
            for _ in 0..<100000 {
                let data = try! Data(contentsOf: file)
                
               measure {
                    let nsData = data as NSData
                    _ = nsData.bytes
                }
            }
        }
    }
    
}

typealias TaskFunc = () -> Void
typealias MeasureFunc = (TaskFunc) -> Void

func myPerformanceTest(_ body: (MeasureFunc) -> Void) {
    var time: UInt64 = 0
    func measure(task: TaskFunc) {
        let start = DispatchTime.now()
        task()
        let end = DispatchTime.now()
        let interval = end.uptimeNanoseconds - start.uptimeNanoseconds
        time += interval
    }
    body(measure)
    let sec = Double(time) / 1000000000
    print(String(format: "%0.6f", sec))
}
