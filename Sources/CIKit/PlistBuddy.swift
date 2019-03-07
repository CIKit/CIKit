import Foundation
import ProcedureKit
import ProcedureKitMac

public final class PlistBuddy: GroupProcedure, InputProcedure {
    
    public enum Command: String {
        case set = "Set"
    }
    
    /// https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
    public enum InfoPlistKeys: String {
        case identifier = "CFBundleIdentifier"
        case displayName = "CFBundleDisplayName"
        case shortName = "CFBundleName"
        case buildNumber = "CFBundleVersion"
        case shortVersionString = "CFBundleShortVersionString"
    }
    
    public typealias Input = (infoPlistPath: String, value: String)
    
    fileprivate class MakeLaunchRequest: TransformProcedure<Input,ProcessProcedure.LaunchRequest> {
        init(command: Command, key: String, standardError: Any? = nil, standardInput: Any? = nil, standardOutput: Any? = nil) {
            super.init { (infoPlistPath, value) in
                let arguments: [String] = ["-c", "Set :\(key) \(value)", infoPlistPath]
                return ProcessProcedure.LaunchRequest(
                    executableURL: URL(fileURLWithPath: "/usr/libexec/PlistBuddy"),
                    arguments: arguments,
                    standardError: standardError,
                    standardInput: standardInput,
                    standardOutput: standardOutput
                )
            }
        }
    }
    
    public var input: Pending<Input> = .pending
    
    public convenience init(_ command: Command, _ key: InfoPlistKeys) {
        self.init(command, key: key.rawValue)
    }
    
    public init(_ command: Command, key: String) {
        
        let makeLaunchRequest = MakeLaunchRequest(command: command, key: key)
        
        let process = ProcessProcedure().injectResult(from: makeLaunchRequest)

        super.init(operations: [ makeLaunchRequest, process])
        
        bind(to: makeLaunchRequest)
    }
}
