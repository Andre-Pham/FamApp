//
//  Trace.swift
//  Fam
//
//  Created by Andre Pham on 13/10/2024.
//

import Foundation

class TraceStack {
    
    private var startTrace: Trace? = nil
    private var endTrace: Trace? = nil
    private var conclusionTrace: Trace? = nil
    private var traces = [Trace]()
    
    init() { }
    
    func trace(_ trace: Trace) {
        switch trace.type {
        case .action, .call, .info:
            if let index = self.traces.firstIndex(where: { $0.time > trace.time }) {
                self.traces.insert(trace, at: index)
            } else {
                self.traces.append(trace)
            }
        case .start:
            self.startTrace = self.startTrace?.merged(with: trace) ?? trace
        case .end:
            self.endTrace = self.endTrace?.merged(with: trace) ?? trace
        case .outcome:
            self.conclusionTrace = self.conclusionTrace?.merged(with: trace) ?? trace
        }
    }
    
    func generate(
        includeTypes: [Trace.TraceType] = Trace.TraceType.allCases,
        expanded: Bool = false
    ) -> String {
        let sortedTraces = [self.startTrace].compactMap({ $0 }) + self.traces + [self.endTrace, self.conclusionTrace].compactMap({ $0 })
        let filteredTraces = sortedTraces.filter({ includeTypes.contains($0.type) })
        let traceDescriptions = filteredTraces.map({ expanded ? $0.expandedDescription : $0.description })
        return traceDescriptions.joined(separator: "\n")
    }
    
}
