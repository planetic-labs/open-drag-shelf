//
//  DragDetector.swift
//  Plupo
//
//  Created by Antigravity on 06.06.2026.
//

import Foundation
import AppKit

class DragDetector {
    static let shared = DragDetector()
    
    private var globalMouseDragMonitor: Any?
    private var localMouseDragMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var localMouseUpMonitor: Any?
    
    private var lastDragChangeCount: Int = -1
    private var isDraggingActive = false
    private var dragExpiry: DispatchWorkItem?
    
    private init() {}
    
    func startMonitoring() {
        // Stop any existing monitors first
        stopMonitoring()
        
        // Monitor global mouse drag (when dragging files from other apps)
        globalMouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.checkDragPasteboard()
        }
        
        // Monitor local mouse drag (dragging within our app, if needed)
        localMouseDragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.checkDragPasteboard()
            return event
        }
        
        // Monitor global mouse up to detect when dragging ends
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp()
        }
        
        localMouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp()
            return event
        }
    }
    
    func stopMonitoring() {
        handleMouseUp()
        if let monitor = globalMouseDragMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseDragMonitor = nil
        }
        if let monitor = localMouseDragMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseDragMonitor = nil
        }
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }
        if let monitor = localMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseUpMonitor = nil
        }
    }
    
    private func checkDragPasteboard() {
        let pasteboard = NSPasteboard(name: .drag)
        guard pasteboard.pasteboardItems?.isEmpty == false else { return }
        let changed = pasteboard.changeCount != lastDragChangeCount
        if changed || isDraggingActive {
            lastDragChangeCount = pasteboard.changeCount
            if !isDraggingActive {
                isDraggingActive = true
                WindowManager.shared.dragDidBegin()
            }
            // Escape may cancel a drag without generating mouseUp.
            dragExpiry?.cancel()
            watchMouseRelease()
        }
    }
    
    private func watchMouseRelease() {
        let expiry = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if NSEvent.pressedMouseButtons & 1 == 0 {
                self.handleMouseUp()
            } else if self.isDraggingActive {
                self.watchMouseRelease()
            }
        }
        dragExpiry = expiry
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: expiry)
    }

    private func handleMouseUp() {
        dragExpiry?.cancel()
        dragExpiry = nil
        guard isDraggingActive else { return }
        isDraggingActive = false
        WindowManager.shared.dragDidEnd()
    }
}
