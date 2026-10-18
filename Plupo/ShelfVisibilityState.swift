import Foundation

struct ShelfVisibilityState {
    private(set) var mode: ShowBehavior = .dragStarts
    var desiredVisible = false
    var dragSources: Set<String> = []
    var itemCount = 0
    var isLoadingDrop = false
    var hasDropError = false

    var canAutoHide: Bool {
        mode == .dragStarts && dragSources.isEmpty && itemCount == 0 && !isLoadingDrop && !hasDropError
    }

    mutating func apply(mode: ShowBehavior) {
        self.mode = mode
        switch mode {
        case .always: desiredVisible = true
        case .shortcut: desiredVisible = false
        case .dragStarts: desiredVisible = itemCount > 0 || !dragSources.isEmpty || isLoadingDrop
        }
    }
}
