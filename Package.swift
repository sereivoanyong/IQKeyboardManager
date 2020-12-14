// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "IQKeyboardManagerSwift",
    products: [
       .library(name: "IQKeyboardManagerSwift", targets: ["IQKeyboardManagerSwift"])
   ],
   targets: [
       .target(
           name: "IQKeyboardManagerSwift",
           path: "IQKeyboardManagerSwift",
           exclude: ["IQKeyboardManagerSwift.h"]
       )
   ]
)
