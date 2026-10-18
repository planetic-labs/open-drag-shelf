# Plupo

Plupo is a macOS menu bar utility that provides a temporary shelf for dragging files, links, text, and images between applications.

## Build

Open `Plupo.xcodeproj` in Xcode and select the `Plupo` scheme. The deployment target is macOS 15.7. For a signed build, select your own development team and unique bundle identifier in Signing & Capabilities. The default identifier is `org.plupo.Plupo`.

To build locally without signing:

```sh
xcodebuild -project Plupo.xcodeproj -scheme Plupo -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Privacy

The current source contains no networking or analytics code. Shelf items are held in memory. Preferences are saved locally in UserDefaults. Dragging text or images out creates temporary export files with restricted permissions; these are removed on normal exit or the next launch. A crash can leave them on disk until that next launch. Links and files can be opened in their associated applications on user action.

Changing the bundle identifier means existing preferences from the former application are not automatically migrated.
