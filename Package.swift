// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BossBattleKit",
    // Set the platforms your game will run on
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces.
        // This makes "BossBattleKit" importable.
        .library(
            name: "BossBattleKit",
            targets: ["BossBattleKit"]),
    ],
    dependencies: [
        // You can add other Swift Packages here if your game needs them.
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        // This is your game's code.
        .target(
            name: "BossBattleKit",
            dependencies: [])
    ]
)
