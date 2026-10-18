# Releasing Plupo

GitHub Actions builds an Apple Silicon DMG only when a version tag is pushed or the workflow is started manually. Ordinary branch pushes and pull requests do not trigger builds.

For a manual build, open **Actions → Build and release Plupo → Run workflow**. Manual builds are retained as workflow artifacts for seven days and do not publish a release.

Pushing a version tag such as `v0.1.1` builds and publishes a GitHub Release with `Plupo-arm64.dmg` and `SHA256SUMS.txt`:

```sh
git tag v0.1.1
git push origin v0.1.1
```

Use a new `vMAJOR.MINOR.PATCH` tag for each release. Tag only reviewed, committed code; local uncommitted changes are not included. Existing release assets are not silently replaced on a rerun.

DMG packaging uses pinned Python tools (`dmgbuild`, `ds-store`, and `mac-alias`) in an isolated environment. These tools are not shipped with the app. The Finder background, icon positions, and window size are defined in `scripts/dmg/`. To regenerate the Retina background after editing its source, run `swift scripts/dmg/render-background.swift`. The app and Applications shortcut are the two visible items; the license and first-launch text remain on the disk as hidden support files.

The workflow uses GitHub-hosted Apple Silicon runners with Xcode 26.3, builds in Release mode, verifies ARM64 output and the ad-hoc signature, and verifies the disk image. The release job alone has permission to write repository contents. No Apple ID, Developer ID certificate, notarization credentials, or custom repository secrets are needed.

Ad-hoc signing is a local integrity signature, not verification of the publisher by Apple. Keep the first-launch notice in the README, release notes, and DMG until Developer ID signing and notarization are added.

To check packaging locally on an Apple Silicon Mac with Xcode selected:

```sh
bash scripts/package-dmg.sh 0.1.1
```

Output is written to `build/distribution/`. Ship only the DMG and checksum, not build logs, DerivedData, debug symbols, certificates, or local configuration. Public release builds should come from GitHub Actions to avoid distributing personal paths from local build machines.

Use a project identity for release commits, for example:

```sh
git -c user.name='Plupo Contributors' \
  -c user.email='contributors@plupo.invalid' commit
```

Before publishing, mount the DMG and check that it contains Plupo, the Applications shortcut, the license, and the installation instructions. A successful build does not replace interactive drag-and-drop QA on macOS.
