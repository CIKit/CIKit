import Foundation
import ProcedureKit
import ProcedureKitMac

public final class Git: GroupProcedure, OutputProcedure {
    
    public struct DescribeOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public enum Command {
        case status
        case tag
        case describe(DescribeOptions?)
    }

    fileprivate class MakeLaunchRequest: TransformProcedure<URL,ProcessProcedure.LaunchRequest> {
        init(_ command: Command, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil) {
            super.init { url in
                return ProcessProcedure.LaunchRequest(
                    executableURL: url,
                    arguments: command.arguments,
                    standardError: standardError,
                    standardInput: standardInput,
                    standardOutput: standardOutput
                )
            }
        }
    }

    public var output: Pending<ProcedureResult<String>> = .pending

    private let outputPipe = Pipe()

    public init(_ command: Command) {

        let which = Which("git")

        let request = MakeLaunchRequest(command, standardOutput: outputPipe).injectResult(from: which)

        let process = ProcessProcedure().injectResult(from: request)
        
        let read = ReadPipe(pipe: outputPipe).injectResult(from: process)
        
        super.init(operations: [which, request, process, read])
        
        bind(from: read)
    }
}


// MARK: - Describe Options

extension Git.DescribeOptions {
    public static let none = Git.DescribeOptions(rawValue: 0)
    public static let all = Git.DescribeOptions(rawValue: 1)
    public static let tags = Git.DescribeOptions(rawValue: 2)

    public var arguments: [String] {
        var args: [String] = []
        if contains(.all) { args.append("--all") }
        if contains(.tags) { args.append("--tags") }
        return args
    }
}


// MARK: - LaunchRequest Helpers

fileprivate extension Git.Command {

    var arguments: [String]? {
        switch self {
        
        case .status:
            return ["status"]
            
        case .tag:
            return ["tag"]
            
        case let .describe(options):
            var args = ["describe"]
            if let optionArgs = options?.arguments {
                args.append(contentsOf: optionArgs)
            }
            return args
        }
    }
}
