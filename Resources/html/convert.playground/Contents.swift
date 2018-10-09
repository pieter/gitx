//#!/usr/bin/swift

import Foundation

////////////////////////////////// library

extension String {
    var isDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: self, isDirectory: &isDir) && isDir.boolValue
    }
}

func /(lhs: String, rhs: String) -> String {
    return (lhs as NSString).appendingPathComponent(rhs)
}

func invert(c: Character) -> Character {
    let value = Int(String(c), radix: 16)!
    let inverted = 15 - value
    let cc = String.init(inverted, radix: 16, uppercase: true)
    return cc.first!
}

func mangle(path: String) throws {
    print(path)
    var html = try String(contentsOfFile: path)
    let regex = try NSRegularExpression(pattern: "#[a-fA-F0-9]+")
    let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.count))
    for match in matches {
        guard (4...7).contains(match.range.length) else { continue }
        let range = Range<String.Index>(match.range, in: html)!
        let color = html[range].dropFirst()
        let inverted = String(color.map(invert))
        html.replaceSubrange(range, with: "#\(inverted)")
        print(color, inverted)
    }
    html.replacingOccurrences(of: "color: white", with: "color: black")
    html.replacingOccurrences(of: "background-color: white", with: "background-color: black")
    try html.write(toFile: path, atomically: true, encoding: .utf8)
}


////////////////////////////////// main
let fm = FileManager.default
let path = fm.currentDirectoryPath == "/" ? "/Users/mxcl/src/GitX/Resources/html" : "."
let enumerator = fm.enumerator(atPath: path)!

while let node = enumerator.nextObject() as? String {
    guard node.hasSuffix(".css") else { continue }
    try mangle(path: path/node)
}
