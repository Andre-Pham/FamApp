//
//  Trace.swift
//  Fam
//
//  Created by Andre Pham on 13/10/2024.
//

import Foundation

class Trace {
    
    private static let THICK_DIVIDER = "=============================================================="
    private static let THIN_DIVIDER =  "--------------------------------------------------------------"
    private static let ACTION_PREFIX = "[TRACE]"
    private static let CALL_PREFIX = "[CALL]"
    private static let START_PREFIX = "[START]"
    private static let END_PREFIX = "[END]"
    
    enum TraceType {
        case action
        case call
        case start
        case end
    }
    
    public let time: Date
    public let type: TraceType
    private let message: String?
    private let functionName: String?
    private var timeDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss.SSSS a"
        return "[\(formatter.string(from: self.time))]"
    }
    private var functionNameDescription: String {
        return self.functionName == nil ? "" : "{\(self.functionName!)}"
    }
    private var messageDescription: String {
        return self.message ?? ""
    }
    public var description: String {
        let components: [String]
        switch self.type {
        case .action:
            components = [Self.ACTION_PREFIX, self.functionNameDescription, self.messageDescription]
        case .call:
            components = [Self.CALL_PREFIX, self.functionNameDescription, self.messageDescription]
        case .start:
            components = [Self.THICK_DIVIDER, "\n", Self.START_PREFIX, self.functionNameDescription, self.messageDescription, "\n", Self.THICK_DIVIDER]
        case .end:
            components = [Self.THICK_DIVIDER, "\n", Self.END_PREFIX, self.functionNameDescription, self.messageDescription, "\n", Self.THICK_DIVIDER]
        }
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    public var expandedDescription: String {
        let components: [String]
        switch self.type {
        case .action:
            components = [Self.THIN_DIVIDER, "\n", Self.ACTION_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription]
        case .call:
            components = [Self.THIN_DIVIDER, "\n", Self.CALL_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription]
        case .start:
            components = [Self.THICK_DIVIDER, "\n", Self.START_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription, "\n", Self.THICK_DIVIDER]
        case .end:
            components = [Self.THICK_DIVIDER, "\n", Self.END_PREFIX, self.timeDescription, self.functionNameDescription, "\n", self.messageDescription, "\n", Self.THICK_DIVIDER]
        }
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }

    init(type: TraceType, message: String?, functionName: String?) {
        self.type = type
        self.message = message
        self.functionName = functionName
        self.time = Date()
    }
    
}
