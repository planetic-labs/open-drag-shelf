//
//  ShelfViewModel.swift
//  Plupo
//
//  Created by Antigravity on 06.06.2026.
//

import Foundation
import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

class ShelfViewModel: ObservableObject {
    @Published var items: [ShelfItem] = []
    var currentlyDraggingItem: ShelfItem? = nil
    
    // Toggle locking state of an item
    func toggleLock(for item: ShelfItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isLocked.toggle()
        }
    }
    
    // Remove specific item
    func removeItem(_ item: ShelfItem) {
        items.removeAll(where: { $0.id == item.id })
        
        // If shelf becomes empty and showBehavior is dragStarts, auto-hide the window
        if items.isEmpty && PreferencesStore.shared.showBehavior == .dragStarts {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.items.isEmpty {
                    WindowManager.shared.hideShelfWindow()
                }
            }
        }
    }
    
    // Remove all items (except locked ones)
    func clearAll() {
        items.removeAll(where: { !$0.isLocked })
        
        if items.isEmpty && PreferencesStore.shared.showBehavior == .dragStarts {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.items.isEmpty {
                    WindowManager.shared.hideShelfWindow()
                }
            }
        }
    }
    
    // Handle drop of NSItemProviders (from Drag & Drop)
    func handleDroppedProviders(_ providers: [NSItemProvider]) {
        
        let group = DispatchGroup()
        var newItems: [ShelfItem] = []
        
        for provider in providers {
            group.enter()
            
            let types = provider.registeredTypeIdentifiers
            
            guard let preferredType = types.first else {
                group.leave()
                continue
            }
            
            provider.loadItem(forTypeIdentifier: preferredType, options: nil) { (item, error) in
                DispatchQueue.main.async {
                    defer { group.leave() }
                    
                    if error != nil {
                        return
                    }
                    
                    guard let item = item else {
                        return
                    }
                    
                    
                    // 1. Check if the item is a URL (local file URL or web link)
                    if let url = item as? URL {
                        if url.isFileURL {
                            newItems.append(ShelfItem(id: UUID(), type: .file, fileURL: url))
                        } else {
                            newItems.append(ShelfItem(id: UUID(), type: .url, url: url, urlTitle: provider.suggestedName))
                        }
                    }
                    else if let nsURL = item as? NSURL {
                        let url = nsURL as URL
                        if url.isFileURL {
                            newItems.append(ShelfItem(id: UUID(), type: .file, fileURL: url))
                        } else {
                            newItems.append(ShelfItem(id: UUID(), type: .url, url: url, urlTitle: provider.suggestedName))
                        }
                    }
                    // 2. Check if the item is Data (image or file data)
                    else if let data = item as? Data {
                        if let utType = UTType(preferredType), utType.conforms(to: .image) {
                            newItems.append(ShelfItem(
                                id: UUID(),
                                type: .image,
                                imageData: data,
                                imageName: provider.suggestedName ?? "Image.png"
                            ))
                        }
                        else if let url = URL(dataRepresentation: data, relativeTo: nil), url.isFileURL {
                            newItems.append(ShelfItem(id: UUID(), type: .file, fileURL: url))
                        }
                    }
                    // 3. Check if the item is String
                    else if let nsString = item as? NSString {
                        let textString = nsString as String
                        
                        if let url = URL(string: textString), url.scheme != nil {
                            newItems.append(ShelfItem(id: UUID(), type: .url, url: url, urlTitle: textString))
                        } else {
                            newItems.append(ShelfItem(id: UUID(), type: .text, text: textString))
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !newItems.isEmpty {
                self.items.append(contentsOf: newItems)
                WindowManager.shared.showShelfWindow()
            }
        }
    }
}
