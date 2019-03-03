import Foundation
import ProcedureKit
import ProcedureKitMac

public final class Which: GroupProcedure, OutputProcedure {
    
    public enum Error: Swift.Error {
        case notFileURL(URL)
    }

    public var output: Pending<ProcedureResult<URL>> = .pending
    
    private let outputPipe = Pipe()
    
    public init(_ command: String) {
        let process = ProcessProcedure(launchPath: "/usr/bin/which", arguments: [command], standardOutput: outputPipe)

        // Read from the output pipe
        let read = ReadPipe(pipe: outputPipe).injectResult(from: process)

        // Parse into a string
        let parse = TransformProcedure<String, URL> { path in
            let url = URL(fileURLWithPath: path.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            guard url.isFileURL else {
                throw Error.notFileURL(url)
            }
            return url
        }.injectResult(from: read)

        super.init(operations: [process, read, parse])

        bind(from: parse)
    }
}
