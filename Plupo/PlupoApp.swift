import SwiftUI
import AppKit

@main
struct PlupoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We don't use the default WindowGroup scene because we manage our windows customly
        // via WindowManager (NSPanel for Shelf, NSWindow for Preferences).
        // Settings scene keeps Xcode happy and prevents default window spawn.
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        PlupoTemporaryFiles.cleanup()

        // Set app as accessory (hides from Dock, acts as background agent)
        NSApp.setActivationPolicy(.accessory)
        
        // Start monitoring system drag events
        DragDetector.shared.startMonitoring()
        
        // Setup Menu Bar Icon
        setupStatusItem()
        
        // If configured to be always visible, show the window right away
        if PreferencesStore.shared.showBehavior == .always {
            WindowManager.shared.showShelfWindow()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        PlupoTemporaryFiles.cleanup()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Plupo")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Shelf", action: #selector(toggleShelf), keyEquivalent: "y"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Plupo", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleShelf() {
        WindowManager.shared.toggleShelfWindow()
    }
    
    @objc func showPreferences() {
        WindowManager.shared.showPreferencesWindow()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
