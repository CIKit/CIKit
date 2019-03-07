import Foundation
import ProcedureKit
import ProcedureKitMac

public enum Xcode { /* Namespace */ }

extension Xcode {

    public struct BuildSettings {

        public enum Key: Hashable {

            public enum Known: String {
                case baseSDK = "SDKROOT"
                case developmentTeam = "DEVELOPMENT_TEAM"
                case infoPlistFile = "INFOPLIST_FILE"
                case iOSDeploymentTarget = "IPHONEOS_DEPLOYMENT_TARGET"
                case macOSDeploymentTarget = "MACOSX_DEPLOYMENT_TARGET"
                case productBundleIdentifier = "PRODUCT_BUNDLE_IDENTIFIER"
                case productModuleName = "PRODUCT_MODULE_NAME"
                case productName = "PRODUCT_NAME"
                case provisioningProfile = "PROVISIONING_PROFILE_SPECIFIER"
            }

            case known(Known)
            case arbitrary(String)
        }

        public enum Value {
            case yes, no, empty
            case arbitrary(String)
        }

        public typealias Settings = [Key: Value]

        public let settings: Settings

        public subscript(key: Key) -> Value? {
            get { return settings[key] }
        }

        public subscript(key: Key.Known) -> Value? {
            get { return settings[.known(key)] }
        }
    }

    public enum Project {
        case project(String)
        case workspaceAndScheme((workspace: String, scheme: String))
    }
}



// MARK: Xcode.BuildSetting.Key RawRepresentable

extension Xcode.BuildSettings.Key: RawRepresentable {

    public var rawValue: String {
        switch self {
        case let .arbitrary(value):
            return value
        case let .known(key):
            return key.rawValue
        }
    }

    public init?(rawValue: String) {
        if let known = Known(rawValue: rawValue) {
            self = .known(known)
        }
        else {
            self = .arbitrary(rawValue)
        }
    }
}


extension Xcode.BuildSettings.Value: RawRepresentable {

    public var rawValue: String {
        switch self {
        case let .arbitrary(value):
            return value
        case .yes:
            return "YES"
        case .no:
            return "NO"
        case .empty:
            return "-"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "YES":
            self = .yes
        case "NO":
            self = .no
        case "-", "":
            self = .empty
        default:
            self = .arbitrary(rawValue)
        }
    }
}

extension Xcode.Project {

    var arguments: [String] {
        switch self {
        case let .project(projectFilePath):
            return ["-project", projectFilePath]
        case .workspaceAndScheme(let workspace, let scheme):
            return ["-workspace","\(workspace)","-scheme","\(scheme)"]
        }
    }
}

// MARK: - Read Xcode Project Settings

extension Xcode.BuildSettings {

    public final class Get: GroupProcedure, InputProcedure, OutputProcedure {

        fileprivate class MakeLaunchRequest: TransformProcedure<URL,ProcessProcedure.LaunchRequest> {
            init(_ project: Xcode.Project, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil) {
                super.init { url in
                    var arguments: [String] = project.arguments
                    arguments.append("-showBuildSettings")
                    return ProcessProcedure.LaunchRequest(
                        executableURL: url,
                        arguments: arguments,
                        standardError: standardError,
                        standardInput: standardInput,
                        standardOutput: standardOutput
                    )
                }
            }
        }

        fileprivate class ParseXcodeBuild: TransformProcedure<[String],Xcode.BuildSettings> {
            init() {
                super.init { output in
                    var settings = Xcode.BuildSettings.Settings()

                    for line in output {
                        let parts = line.components(separatedBy: "=")
                        guard parts.count == 2,
                            let key = Xcode.BuildSettings.Key(rawValue: parts[0].trimmingCharacters(in: CharacterSet.whitespaces)),
                            let value = Xcode.BuildSettings.Value(rawValue: parts[1].trimmingCharacters(in: CharacterSet.whitespaces))
                        else { continue }
                        settings[key] = value
                    }
                    return Xcode.BuildSettings(settings: settings)
                }
            }
        }

        public var input: Pending<Xcode.Project> = .pending
        public var output: Pending<ProcedureResult<Xcode.BuildSettings>> = .pending

        private let outputPipe = Pipe()

        fileprivate let parse: ParseXcodeBuild

        public init(_ project: Xcode.Project? = nil) {

            if let project = project {
                input = .ready(project)
            }

            parse = ParseXcodeBuild()

            super.init(operations: [])

            bind(from: parse)
        }

        public override func execute() {

            guard let project = input.value else {
                finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
                return
            }

            let which = Which("xcodebuild")

            let request = MakeLaunchRequest(project, standardOutput: outputPipe).injectResult(from: which)

            let process = ProcessProcedure().injectResult(from: request)
            process.log.severity = .verbose

            process.addWillExecuteBlockObserver { (process, _) in
                if let url = process.input.value?.executableURL, let args = process.input.value?.arguments {
                    process.log.debug.message("Will execute \(url) \(args)")
                }
            }

            let read = ReadPipe(pipe: outputPipe).injectResult(from: process)

            let parseIntoLines = ParseStringIntoLines().injectResult(from: read)

            parse.injectResult(from: parseIntoLines)

            addChildren(which, request, process, read, parseIntoLines, parse)

            super.execute()
        }
    }
}

