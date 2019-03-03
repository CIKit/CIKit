import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CIKitTests.allTests),
    ]
}
#endif