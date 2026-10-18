//
//  PreferencesView.swift
//  Plupo
//
//  Created by Antigravity on 06.06.2026.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var prefs: PreferencesStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Settings Banner
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Plupo")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Power up your drag-and-drop workflow.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(Color.primary.opacity(0.03))
            
            Divider()
            
            // Preferences Form
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Section 1: Window Position & Behavior
                    GroupBox(label: Text("Position & Behavior").font(.system(size: 11, weight: .bold))) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Screen Edge:")
                                    .frame(width: 110, alignment: .leading)
                                Picker("", selection: $prefs.position) {
                                    ForEach(ShelfPosition.allCases, id: \.self) { pos in
                                        Text(pos.rawValue).tag(pos)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            HStack {
                                Text("Alignment:")
                                    .frame(width: 110, alignment: .leading)
                                Picker("", selection: $prefs.alignment) {
                                    ForEach(ShelfAlignment.allCases, id: \.self) { align in
                                        Text(align.rawValue).tag(align)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            HStack {
                                Text("Show Shelf:")
                                    .frame(width: 110, alignment: .leading)
                                Picker("", selection: $prefs.showBehavior) {
                                    ForEach(ShowBehavior.allCases, id: \.self) { behavior in
                                        Text(behavior.rawValue).tag(behavior)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    
                    // Section 2: Items & Dragging
                    GroupBox(label: Text("Items & Dragging").font(.system(size: 11, weight: .bold))) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Card Size:")
                                    .frame(width: 110, alignment: .leading)
                                Picker("", selection: $prefs.iconSize) {
                                    ForEach(IconSize.allCases, id: \.self) { size in
                                        Text(size.rawValue).tag(size)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            Toggle("Keep items on shelf after dragging them out", isOn: $prefs.keepItemsAfterDrag)
                                .font(.system(size: 11))
                            
                            Text("By default, items are automatically removed from Plupo when you drag them into another application.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.leading, 18)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                    
                    // Section 3: General System
                    GroupBox(label: Text("System").font(.system(size: 11, weight: .bold))) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Launch Plupo at login", isOn: $prefs.launchAtLogin)
                                .font(.system(size: 11))
                            
                            Text("Starts the app automatically when you log into your Mac so it's always ready.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.leading, 18)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Bottom bar
            HStack {
                Spacer()
                Button("Done") {
                    // Close the window using the WindowManager or standard NSApp closing
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 450, height: 460)
    }
}

#Preview {
    PreferencesView()
        .environmentObject(PreferencesStore.shared)
}
