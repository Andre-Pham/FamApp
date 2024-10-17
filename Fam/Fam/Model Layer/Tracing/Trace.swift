//
//  Trace.swift
//  Fam
//
//  Created by Andre Pham on 13/10/2024.
//

import Foundation

class Trace {
    
    private static let HEAVY_DIVIDER = "##############################################################"
    private static let MEDIUM_DIVIDER = "=============================================================="
    private static let LIGHT_DIVIDER = "--------------------------------------------------------------"
    private static let ACTION_PREFIX = "[TRACE]"
    private static let CALL_PREFIX = "[CALL]"
    private static let START_PREFIX = "[START]"
    private static let END_PREFIX = "[END]"
    private static let INFO_PREFIX = "[INFO]"
    
    enum TraceType: CaseIterable {
        /// Something was done
        case action
        /// Something was called
        case call
        /// Started the trace stack
        case start
        /// Ended the trace stack
        case end
        /// Informative message
        case info
        /// Outcome of the trace stack
        case outcome
    }
    
    public let time: Date
    public let type: TraceType
    private let functionName: String?
    private let message: String?
    private var timeDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss.SSSS a"
        return "[\(formatter.string(from: self.time))]"
    }
    private var functionNameDescription: String {
        let cleaned = self.functionName?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let cleaned, cleaned.count > 0 else {
            return ""
        }
        return "{\(cleaned)}"
    }
    private var messageDescription: String {
        let cleaned = self.message?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let cleaned, cleaned.count > 0 else {
            return ""
        }
        return switch self.type {
        case .start, .end:
            cleaned.uppercased()
        default:
            cleaned
        }
    }
    public var description: String {
        let components: [String]
        switch self.type {
        case .action:
            components = [Self.ACTION_PREFIX, self.functionNameDescription, self.messageDescription]
        case .call:
            components = [Self.CALL_PREFIX, self.functionNameDescription, self.messageDescription]
        case .start:
            components = [Self.MEDIUM_DIVIDER, "\n", Self.START_PREFIX, self.functionNameDescription, self.messageDescription, "\n", Self.MEDIUM_DIVIDER]
        case .end:
            components = [Self.MEDIUM_DIVIDER, "\n", Self.END_PREFIX, self.functionNameDescription, self.messageDescription, "\n", Self.MEDIUM_DIVIDER]
        case .info:
            components = [Self.INFO_PREFIX, self.functionNameDescription, self.messageDescription]
        case .outcome:
            components = [Self.HEAVY_DIVIDER, "\n", self.functionNameDescription, self.messageDescription, "\n", Self.HEAVY_DIVIDER]
        }
        return components
            .filter({ !$0.isEmpty })
            .reduce("") { result, component in
                if component == "\n" {
                    if result.hasSuffix("\n") {
                        return result
                    } else {
                        return result + component
                    }
                } else if result.isEmpty || result.hasSuffix("\n") {
                    return result + component
                } else {
                    return result + " " + component
                }
            }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    public var expandedDescription: String {
        let components: [String]
        switch self.type {
        case .action:
            components = [Self.LIGHT_DIVIDER, "\n", Self.ACTION_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription]
        case .call:
            components = [Self.LIGHT_DIVIDER, "\n", Self.CALL_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription]
        case .start:
            components = [Self.MEDIUM_DIVIDER, "\n", Self.START_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription, "\n", Self.MEDIUM_DIVIDER]
        case .end:
            components = [Self.MEDIUM_DIVIDER, "\n", Self.END_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription, "\n", Self.MEDIUM_DIVIDER]
        case .info:
            components = [Self.INFO_PREFIX, self.functionNameDescription, self.messageDescription]
        case .outcome:
            components = [Self.HEAVY_DIVIDER, "\n", self.functionNameDescription, self.messageDescription, "\n", Self.HEAVY_DIVIDER]
        }
        return components
            .filter({ !$0.isEmpty })
            .reduce("") { result, component in
                if component == "\n" {
                    if result.hasSuffix("\n") {
                        return result
                    } else {
                        return result + component
                    }
                } else if result.isEmpty || result.hasSuffix("\n") {
                    return result + component
                } else {
                    return result + " " + component
                }
            }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(type: TraceType, functionName: String? = nil, message: String? = nil) {
        self.type = type
        self.functionName = functionName
        self.message = message
        self.time = Date()
    }
    
    private init(type: TraceType, functionName: String?, message: String?, time: Date) {
        self.type = type
        self.functionName = functionName
        self.message = message
        self.time = time
    }
    
    func merged(with other: Trace) -> Trace {
        var mergedFunctionName: String? = nil
        if !self.functionNameDescription.isEmpty && !other.functionNameDescription.isEmpty {
            mergedFunctionName = "\(self.functionName ?? "") + \(other.functionName ?? "")"
        } else if !self.functionNameDescription.isEmpty {
            mergedFunctionName = self.functionName
        } else if !other.functionNameDescription.isEmpty {
            mergedFunctionName = other.functionName
        }
        var mergedMessage: String? = nil
        if !self.messageDescription.isEmpty && !other.messageDescription.isEmpty {
            mergedMessage = "\(self.message ?? "")\n\(other.message ?? "")"
        } else if !self.messageDescription.isEmpty {
            mergedMessage = self.message
        } else if !other.messageDescription.isEmpty {
            mergedMessage = other.message
        }
        let mergedTime = [self.time, other.time].min()!
        return Trace(
            type: self.type == other.type ? self.type : .info,
            functionName: mergedFunctionName,
            message: mergedMessage,
            time: mergedTime
        )
    }
    
}
