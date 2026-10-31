// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "MyEvent", platforms: [.macOS(.v14)], products: [.executable(name: "MyEvent", targets: ["MyEvent"])], targets: [.executableTarget(name: "MyEvent"), .testTarget(name: "MyEventTests", dependencies: ["MyEvent"])])
