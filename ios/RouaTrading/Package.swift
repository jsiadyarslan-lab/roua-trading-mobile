// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RouaTrading",
    platforms: [.iOS(.v17)],
    products: [
        .executable(name: "RouaTrading", targets: ["RouaTradingApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "RouaTradingApp",
            dependencies: [
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            path: "RouaTrading/Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
