import Foundation
import ShellOut
import ProcedureKit
import ProcedureKitMac

public final class Git: ResultProcedure<String> {
    
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

    public init(_ command: Command) {
        super.init { try shellOut(to: command.shell) }
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

    var shell: ShellOutCommand {
        switch self {

        case .status:
            return ShellOutCommand(string: "git status")

        case .tag:
            return ShellOutCommand(string: "git tag")

        case let .describe(options):
            var args = ["describe"]
            if let optionArgs = options?.arguments {
                args.append(contentsOf: optionArgs)
            }
            var command = "git "
            command.append(contentsOf: args.map { return " \($0)" }.joined())
            return ShellOutCommand(string: command)
        }
    }
}
