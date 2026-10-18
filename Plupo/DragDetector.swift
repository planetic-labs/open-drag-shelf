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
        // Get the drag pasteboard
        let dragPasteboard = NSPasteboard(name: .drag)
        let currentChangeCount = dragPasteboard.changeCount
        
        // If the change count has changed, and there are items on the drag pasteboard,
        // it means a drag operation has officially started in the OS.
        if currentChangeCount != lastDragChangeCount {
            lastDragChangeCount = currentChangeCount
            
            if let items = dragPasteboard.pasteboardItems, !items.isEmpty {
                isDraggingActive = true
                
                // Only trigger if showBehavior is set to dragStarts
                if PreferencesStore.shared.showBehavior == .dragStarts {
                    DispatchQueue.main.async {
                        WindowManager.shared.showShelfWindow()
                    }
                }
            }
        }
    }
    
    private func handleMouseUp() {
        if isDraggingActive {
            isDraggingActive = false
            
            // If dragging ended and the shelf is empty, hide it (with a slight delay)
            if PreferencesStore.shared.showBehavior == .dragStarts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Check if shelf is empty, if so, hide it
                    if WindowManager.shared.shelfViewModel.items.isEmpty {
                        WindowManager.shared.hideShelfWindow()
                    }
                }
            }
        }
        
        // Handle drag-out detection for Plupo items
        if let draggedItem = WindowManager.shared.shelfViewModel.currentlyDraggingItem {
            WindowManager.shared.shelfViewModel.currentlyDraggingItem = nil
            
            let mouseLocation = NSEvent.mouseLocation
            // Check if the drop location is outside the Plupo shelf panel frame
            if !WindowManager.shared.isMouseInsideShelf(at: mouseLocation) {
                DispatchQueue.main.async {
                    if !draggedItem.isLocked && !PreferencesStore.shared.keepItemsAfterDrag {
                        WindowManager.shared.shelfViewModel.removeItem(draggedItem)
                    }
                }
            }
        }
    }
}
