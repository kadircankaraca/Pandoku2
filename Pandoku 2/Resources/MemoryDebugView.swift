//
//  MemoryDebugView.swift
//  Pandoku 2
//

import SwiftUI

struct MemoryDebugView: View {
    @State private var memoryUsage: String = "Calculating..."
    
    var body: some View {
        VStack {
            Text("Memory Usage")
                .font(.headline)
            Text(memoryUsage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .onAppear {
            updateMemoryUsage()
        }
        .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
            updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            memoryUsage = String(format: "%.1f MB", usedMB)
        } else {
            memoryUsage = "Error"
        }
    }
}

#Preview {
    MemoryDebugView()
}
