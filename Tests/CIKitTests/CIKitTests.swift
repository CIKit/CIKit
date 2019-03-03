import XCTest
@testable import CIKit

final class CIKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CIKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
