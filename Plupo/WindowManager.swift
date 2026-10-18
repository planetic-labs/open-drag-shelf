//
//  WindowManager.swift
//  Plupo
//
//  Created by Antigravity on 06.06.2026.
//

import SwiftUI
import AppKit
import Combine

class WindowManager: NSObject, ObservableObject {
    static let shared = WindowManager()
    
    let shelfViewModel = ShelfViewModel()
    
    private var shelfPanel: NSPanel?
    private var preferencesWindow: NSWindow?
    
    private let windowWidth: CGFloat = 150
    private let windowHeight: CGFloat = 420
    private var isAnimating = false
    
    private override init() {
        super.init()
        setupPreferencesObserver()
    }
    
    private func setupPreferencesObserver() {
        // Observe preference changes to update window position dynamically
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateShelfPosition(animated: true)
        }
    }
    
    func isMouseInsideShelf(at point: NSPoint) -> Bool {
        guard let panel = shelfPanel else { return false }
        return NSMouseInRect(point, panel.frame, false)
    }
    
    private var isShelfVisible = false
    
    func showShelfWindow() {
        if shelfPanel == nil {
            createShelfPanel()
        }
        
        guard let panel = shelfPanel, !isShelfVisible else {
            updateShelfPosition(animated: true)
            return
        }
        
        isShelfVisible = true
        let screen = getActiveScreen()
        let targetFrame = getTargetFrame(for: screen, isVisibleState: true)
        
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1.0
        }, completionHandler: {
            self.isAnimating = false
        })
    }
    
    func hideShelfWindow() {
        guard let panel = shelfPanel, isShelfVisible, !isAnimating else { return }
        
        isShelfVisible = false
        let screen = getActiveScreen()
        let hiddenFrame = getTargetFrame(for: screen, isVisibleState: false)
        
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(hiddenFrame, display: true)
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            self.isAnimating = false
        })
    }
    
    func toggleShelfWindow() {
        if isShelfVisible {
            hideShelfWindow()
        } else {
            showShelfWindow()
        }
    }
    
    private func createShelfPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        
        // Host the SwiftUI View inside the panel
        let shelfView = ShelfView(viewModel: shelfViewModel)
            .environmentObject(PreferencesStore.shared)
        
        let hostingView = NSHostingView(rootView: shelfView)
        hostingView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        panel.contentView = hostingView
        
        self.shelfPanel = panel
        
        // Position it hidden initially and show it immediately to avoid reentrant drag logs later
        let screen = getActiveScreen()
        let hiddenFrame = getTargetFrame(for: screen, isVisibleState: false)
        panel.setFrame(hiddenFrame, display: true)
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()
    }
    
    private func updateShelfPosition(animated: Bool) {
        guard let panel = shelfPanel, !isAnimating else { return }
        
        let screen = getActiveScreen()
        let targetFrame = getTargetFrame(for: screen, isVisibleState: isShelfVisible)
        
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                panel.animator().setFrame(targetFrame, display: true)
            })
        } else {
            panel.setFrame(targetFrame, display: true)
        }
    }
    
    // Calculates the window frame based on active screen and settings
    private func getTargetFrame(for screen: NSScreen, isVisibleState: Bool) -> NSRect {
        let prefs = PreferencesStore.shared
        let screenFrame = screen.visibleFrame
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        // Calculate X Position
        if prefs.position == .left {
            if isVisibleState {
                x = screenFrame.minX + 8
            } else {
                x = screenFrame.minX - windowWidth - 20
            }
        } else { // Right
            if isVisibleState {
                x = screenFrame.maxX - windowWidth - 8
            } else {
                x = screenFrame.maxX + 20
            }
        }
        
        // Calculate Y Position
        switch prefs.alignment {
        case .top:
            y = screenFrame.maxY - windowHeight - 20
        case .center:
            y = screenFrame.minY + (screenFrame.height - windowHeight) / 2
        case .bottom:
            y = screenFrame.minY + 20
        }
        
        return NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
    }
    
    private func getActiveScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        
        // 1. Try to find the screen that directly contains the mouse cursor
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) {
            return screen
        }
        
        // 2. If the mouse is slightly outside of all screens (e.g. during a drag near boundaries),
        // find the screen that is closest to the mouse cursor.
        if let closestScreen = NSScreen.screens.min(by: { 
            let dist0 = distance(from: mouseLocation, to: $0.frame)
            let dist1 = distance(from: mouseLocation, to: $1.frame)
            return dist0 < dist1
        }) {
            return closestScreen
        }
        
        // 3. Absolute fallbacks
        return NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }
    
    private func distance(from point: NSPoint, to rect: NSRect) -> CGFloat {
        let dx = max(0, max(rect.minX - point.x, point.x - rect.maxX))
        let dy = max(0, max(rect.minY - point.y, point.y - rect.maxY))
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Preferences Window management
    
    func showPreferencesWindow() {
        if preferencesWindow == nil {
            createPreferencesWindow()
        }
        
        // Switch to regular app temporarily so preferences window has a menu bar and behaves properly
        NSApp.setActivationPolicy(.regular)
        
        preferencesWindow?.center()
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createPreferencesWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Plupo Preferences"
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        let prefsView = PreferencesView()
            .environmentObject(PreferencesStore.shared)
        
        window.contentView = NSHostingView(rootView: prefsView)
        self.preferencesWindow = window
    }
}

// Keep application working in accessory mode when preferences close
extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == preferencesWindow {
            // Switch back to accessory (background/menu-bar only) mode
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
