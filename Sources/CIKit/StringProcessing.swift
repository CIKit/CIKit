import Foundation
import ProcedureKit

public final class ParseStringIntoLines: TransformProcedure<String,[String]> {
    public init() {
        super.init { strings in
            return strings
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }
}
