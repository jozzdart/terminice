# Repository tools

This directory contains small maintenance tools used by the Terminice
repository. These tools are not part of any published Dart package.

## README synchronization

`sync_readme.dart` keeps the repository's root `README.md` synchronized with
`terminice/README.md`.

The package README is the source of truth, but its local links are relative to
the `terminice/` directory. A direct copy at the repository root would therefore
point assets and examples at the wrong locations. The synchronization tool
copies the package README to the root and prefixes local paths that resolve
inside the package with `terminice/`.

The tool leaves the package README unchanged. It also leaves external URLs,
page anchors, absolute paths, missing paths, and content inside fenced code
blocks unchanged.

### Usage

Run the tool from the repository root whenever `terminice/README.md` changes:

```bash
dart tool/sync_readme.dart
```

The script resolves the repository from its own location, so it can also be
called with an absolute path from another directory:

```bash
dart /path/to/terminice/tool/sync_readme.dart
```

A successful run reports how many local paths were adjusted:

```text
Synced terminice/README.md to README.md and adjusted 54 local paths.
```

Review the generated root README before committing:

```bash
git diff -- README.md
```
