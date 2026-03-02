//
//  ReachabilityManager.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SystemConfiguration
import Network

final class ReachabilityManager {
    
    private static let monitor = NWPathMonitor()
    private static let queue = DispatchQueue(label: "ReachabilityMonitor")
    private static var isMonitoring = false
    private static var currentStatus: NWPath.Status = .requiresConnection
    
    // Start monitoring once
    static func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { path in
            currentStatus = path.status
        }
        
        monitor.start(queue: queue)
        isMonitoring = true
    }
    
    // Simple check
    static func isOnline() -> Bool {
        return currentStatus == .satisfied
    }
}
