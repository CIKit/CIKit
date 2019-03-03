import Foundation
import ProcedureKit
import ProcedureKitMac

public final class ReadPipe: Procedure, OutputProcedure, InputProcedure {

    enum Error: Swift.Error, Equatable {
        case noData
        case stringDecodingError(Data)
    }

    let pipe: Pipe
    let encoding: String.Encoding

    private var data = Data()
    private let queue = DispatchQueue(label: "read-data-from-pipe-queue")

    public var input: Pending<ProcessProcedure.TerminationResult> = .pending
    public var output: Pending<ProcedureResult<String>> = .pending

    public init(pipe: Pipe, encoding: String.Encoding = .utf8) {
        self.pipe = pipe
        self.encoding = encoding
        super.init()
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handler in
            guard let this = self else { return }
            this.queue.async {
                this.data.append(handler.availableData)
            }
        }
    }

    public override func execute() {
        guard data.count > 0 else {
            finish(withResult: .failure(Error.noData))
            return
        }
        guard let string = String(data: data, encoding: encoding)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            finish(withResult: .failure(Error.stringDecodingError(data)))
            return
        }
        finish(withResult: .success(string))
    }
}

