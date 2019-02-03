import Foundation

class Resources {
    init() {
        let repoDir = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let swiftpmBuildDir = repoDir.appendingPathComponent(".build")
        
        var isInSwiftPM = false
        
        let args = ProcessInfo.processInfo.arguments
        if 1 < args.count {
            if args[1].starts(with: swiftpmBuildDir.path) {
                isInSwiftPM = true
            }
        }
        
        self.repoDir = repoDir
        self.isInSwiftPM = isInSwiftPM
    }
    
    let repoDir: URL
    let isInSwiftPM: Bool
    
    static var shared: Resources = Resources()
    
    func path(_ string: String) -> URL {
        if isInSwiftPM {
            return repoDir.appendingPathComponent("Tests/RichJSONParserTests/Resources")
                .appendingPathComponent(string)
        } else {
            return Bundle(for: Resources.self).resourceURL!
                .appendingPathComponent("Resources")
                .appendingPathComponent(string)
        }
    }
}
