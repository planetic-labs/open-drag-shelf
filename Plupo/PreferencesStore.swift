//
//  PreferencesStore.swift
//  Plupo
//
//  Created by Antigravity on 06.06.2026.
//

import Foundation
import Combine

enum ShelfPosition: String, Codable, CaseIterable {
    case left = "Left"
    case right = "Right"
}

enum ShelfAlignment: String, Codable, CaseIterable {
    case top = "Top"
    case center = "Center"
    case bottom = "Bottom"
}

enum ShowBehavior: String, Codable, CaseIterable {
    case dragStarts = "When Drag Starts"
    case always = "Always Visible"
    case shortcut = "Shortcut Only"
}

enum IconSize: String, Codable, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
}

class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()
    
    private let defaults = UserDefaults.standard
    
    @Published var position: ShelfPosition {
        didSet { defaults.set(position.rawValue, forKey: "position") }
    }
    
    @Published var alignment: ShelfAlignment {
        didSet { defaults.set(alignment.rawValue, forKey: "alignment") }
    }
    
    @Published var showBehavior: ShowBehavior {
        didSet { defaults.set(showBehavior.rawValue, forKey: "showBehavior") }
    }
    
    @Published var keepItemsAfterDrag: Bool {
        didSet { defaults.set(keepItemsAfterDrag, forKey: "keepItemsAfterDrag") }
    }
    
    @Published var iconSize: IconSize {
        didSet { defaults.set(iconSize.rawValue, forKey: "iconSize") }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }
    
    private init() {
        self.position = ShelfPosition(rawValue: defaults.string(forKey: "position") ?? "") ?? .right
        self.alignment = ShelfAlignment(rawValue: defaults.string(forKey: "alignment") ?? "") ?? .center
        self.showBehavior = ShowBehavior(rawValue: defaults.string(forKey: "showBehavior") ?? "") ?? .dragStarts
        self.keepItemsAfterDrag = defaults.object(forKey: "keepItemsAfterDrag") as? Bool ?? false
        self.iconSize = IconSize(rawValue: defaults.string(forKey: "iconSize") ?? "") ?? .medium
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
    }
}
