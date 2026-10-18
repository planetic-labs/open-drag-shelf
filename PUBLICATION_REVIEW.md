# Plupo publication review

Reviewed on 2026-10-18: current source, project settings, tracked paths, and 50 historical file blobs reachable from all local Git refs. Pattern checks covered common private keys, GitHub/AWS/service tokens, secret assignments, email addresses, and local user paths. This is a scoped review, not a guarantee that all secrets or vulnerabilities are absent.

## Changes

- Renamed source directory, Xcode project, target, product, app entry point, interface labels, and source references to Plupo.
- Set the default bundle identifier to `org.plupo.Plupo` and removed the developer team binding.
- Removed diagnostic output that exposed file paths, URLs, text excerpts, item names, and error details.
- Isolated temporary drag exports by item ID, sanitized provider filenames, restricted directory/file permissions, and added cleanup on exit and next launch.
- Added ignore rules for common local secrets, signing assets, logs, and build output.

## History reset

The earlier local history contained author name/email metadata, a developer team identifier, and Xcode user state with local filesystem paths. The local repository was reset to one initial commit containing the reviewed Plupo source. Old local refs and reflogs were removed and unreachable Git objects pruned. The initial commit uses a neutral project identity (`Plupo Contributors <contributors@plupo.invalid>`).

The GitHub remote has not been updated. Its previous history may still be available until separately replaced; existing clones, forks, and cached copies are outside this local cleanup.

## Remaining limitations

The workspace directory and existing Git remote retain their original names. No remote repository was renamed or published. The app has not received interactive drag-and-drop QA in this review. The launch-at-login setting currently saves a preference but does not register a login item. The app icon asset has no supplied artwork. No distribution license has been chosen.
