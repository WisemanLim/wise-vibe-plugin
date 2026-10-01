// swift-tools-version:6.0
// {{PROJECT_NAME}} — SwiftPM manifest (정적 템플릿 / static scaffold)
import PackageDescription

let package = Package(
    name: "{{PROJECT_NAME}}",
    platforms: [.iOS(.v17)],
    targets: [
        .target(name: "App", path: "App/Sources"),
        .testTarget(name: "AppTests", dependencies: ["App"], path: "AppTests")
    ]
)
