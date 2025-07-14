import Foundation

let testDBName = "miracl"

@objc class DBFileHelper: NSObject {
    @objc class func getDBFilePath() -> String {
        var path = ""
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            path = fileURL.appendingPathComponent("\(testDBName).sqlite").relativePath
        } catch {
            return path
        }
        return path
    }
}
