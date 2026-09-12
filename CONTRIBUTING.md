# Contributing to GRIDRUNNER

## Engine baseline

Use Godot 4.7.2 stable with the Compatibility renderer. Opening and saving the project with another engine version can rewrite `project.godot`, scenes, resources, and import metadata. Make engine upgrades in a dedicated branch and commit so they can be reviewed separately from gameplay changes.

## What belongs in Git

Commit the editable project source and the metadata required to reproduce it:

- `project.godot`, scripts, text scenes, resources, shaders, and tests.
- Source art, models, audio, fonts, and other runtime assets.
- Every `<asset>.import` sidecar generated next to a source asset.
- Every `.uid` sidecar generated for scripts, shaders, and other resources.
- `export_presets.cfg` when export presets are added.

Do not commit `.godot/`, `.import/`, generated exports, temporary files, editor settings, or `export_credentials.cfg`. The repository `.gitignore` contains the shared rules.

## Day-to-day workflow

1. Close Godot before switching branches or resolving project-file conflicts.
2. Start from a clean working tree and pull before beginning work.
3. Keep one logical change per commit. Commit a changed source asset together with its `.import` sidecar.
4. Move or rename resources in Godot's FileSystem dock when practical. If moving a script or shader externally, move its `.uid` sidecar with it.
5. Review `project.godot`, `.tscn`, `.tres`, `.import`, and `.uid` diffs before committing editor-generated changes.
6. Avoid editing the same scene or `project.godot` concurrently. Prefer smaller reusable scenes and `.tres` resources to reduce merge conflicts.
7. Keep generated screenshots and logs only when they are intentional validation artifacts.

Use `res://` for project resources and `user://` for runtime saves and settings. Do not commit machine-specific absolute paths.

## Validation

Run from the repository root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/native_smoke.gd
godot --headless --path . --script tests/vertical_slice_02.gd
godot --headless --path . --script tests/polish_regression.gd
godot --headless --path . --script tests/asset_integration_regression.gd
godot --headless --path . --script tests/performance_regression.gd
```

Large binary assets are currently small enough for ordinary Git. Introduce Git LFS before adding large or frequently changing binary source files; do not partially migrate existing assets in an unrelated change.
