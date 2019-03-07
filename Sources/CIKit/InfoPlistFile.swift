import Foundation
import ProcedureKit
import ProcedureKitMac

public final class GetInfoPlistFile: ResultProcedure<String> {
    
    public enum Error: Swift.Error {
        case unableToDetermineInfoPlistPath
    }

    public init() {
        super.init {
            let vars = ProcessInfo.processInfo.environment
            guard let buildProductsDirectory = vars["BUILT_PRODUCTS_DIR"], let infoPlistPath = vars["INFOPLIST_PATH"] else {
                throw Error.unableToDetermineInfoPlistPath
            }
            return (buildProductsDirectory as NSString).appendingPathComponent(infoPlistPath)
        }
    }
}
