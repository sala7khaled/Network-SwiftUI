//
//  Connectivity.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation
import Network
import Combine

final class Connectivity {
    
    // MARK: - Properties
    static let shared = Connectivity()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ReachabilityMonitor")
    private var lastStatus: NWPath.Status = .requiresConnection
    private var isFirstUpdate = true
    
    // MARK: - Public
    var isOnline: Bool { lastStatus == .satisfied }
    
    // MARK: - Methods
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            
            if self.isFirstUpdate {
                self.isFirstUpdate = false
                self.lastStatus = path.status
                return
            }
            
            guard path.status != self.lastStatus else { return }
            self.lastStatus = path.status
            
            DispatchQueue.main.async {
                self.handleStatusChange(path.status)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - Handle Changes
    private func handleStatusChange(_ status: NWPath.Status) {
        
        let type: ToastEntry = status == .satisfied ? .online : .offline
        let message = String(localized: status == .satisfied ? "online" : "offline")
        
        Toaster.shared.show(type: type, message)
        
//        switch status {
//        case .satisfied:
//            Toaster.shared.show(type: .online, String(localized: "online"))
//            
//        case .unsatisfied, .requiresConnection:
//            Toaster.shared.show(type: .offline, String(localized: "offline"))
//            
//        @unknown default:
//            break
//        }
    }
}
