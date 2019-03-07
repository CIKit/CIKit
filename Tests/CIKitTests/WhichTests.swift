import XCTest
import ProcedureKitMac
import TestingProcedureKit
@testable import CIKit

final class WhichTest: ProcedureKitTestCase {

    func test_which__with_existing_executable() {
        let ls = Which("ls")
        wait(for: ls)
        PKAssertProcedureOutput(ls, URL(fileURLWithPath: "/bin/ls"))
    }

    func test_which__with_nonexisted_executable() {
        let foo = Which("foo")
        wait(for: foo)
        PKAssertProcedureError(foo, ProcessProcedure.Error.didNotExitCleanly(1, Process.TerminationReason.exit))
    }
    
    static var allTests = [
        ("test_which__with_existing_executable", test_which__with_existing_executable),
        ("test_which__with_nonexisted_executable", test_which__with_nonexisted_executable)
    ]
}
