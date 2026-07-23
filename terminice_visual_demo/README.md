# Terminice Visual Demo

A static screenshot and recording page for real Terminice terminal visuals.

Open [`index.html`](index.html) directly in a browser. There is no server and no browser-side package install. The page reads [`frames.js`](frames.js), which is generated from real Terminice runs by [`generate.dart`](generate.dart).

## Main Showcase

The default page is a simple split view: code on the left, captured terminal output on the right, controls at the bottom.

Each tick changes the component. Every five component changes, the theme changes. The terminal area is rendered from captured Terminice output, not hand-drawn markup.

When the theme changes, the first code line changes too:

```dart
final t = terminice.neon;
```

Use the controls to tune rotation speed, code text size, terminal text size, and how much horizontal space the code pane receives.

```text
index.html
```

Recommended capture sizes:

- `1440 x 900` for README hero screenshots.
- `1200 x 760` for tighter docs images.
- `1920 x 1080` for video or social previews.

## Choose Rotating Components

Open [`index.html`](index.html) and find `demoComponentIds`.

Every component has a variable above it, and the rotation list is intentionally easy to edit:

```js
const demoComponentIds = [
  componentText,
  componentPassword,
  componentFilePicker,
  // componentFlow,
];
```

Comment out anything you do not want in the main visual rotation. Direct links such as `?component=flow` still work even if that component is commented out of the default rotation.

## Per-Component Visuals

Lock the component with `?component=...`. The component stays the same while themes keep rotating.

```text
index.html?component=text
index.html?component=password
index.html?component=filePicker
index.html?component=progressBar
index.html?component=flow
index.html?component=customComponents
```

This is useful for each component's documentation because one page can generate a focused visual without duplicating markup.

## Static Screenshot Mode

Use `?still=1` when you want a stable frame.

```text
index.html?component=searchSelector&still=1
```

Supported query params:

- `component` or `c` locks a component.
- `speed` changes rotation speed in milliseconds (`200` to `5000`).
- `codeSize` sets the code font size in pixels.
- `terminalSize` sets the terminal font size in pixels.
- `split` sets the code pane width percentage.
- `still=1` or `motion=off` disables rotation.

## Static Three-Theme Gallery

Open [`theme-gallery.html`](theme-gallery.html) for a screenshot-friendly board that renders every component in three unlabeled preview columns: `fire`, `matrix`, and `arcane`.

```text
theme-gallery.html
```

This page is useful when you want one tall visual that compares the most expressive themes across the full catalogue without extra titles, labels, or UI chrome.

## Generate SVGs For Component Docs

Run the SVG generator whenever `frames.js` changes:

```text
node terminice_visual_demo/generate_component_svgs.mjs
```

It reads the real captured frames, writes one pure SVG triptych per component to `terminice/assets/component_showcases/`, and updates the matching dedicated README sections with guarded image blocks.

Use `--assets-only` when you only want to refresh the SVG files without touching the README:

```text
node terminice_visual_demo/generate_component_svgs.mjs --assets-only
```

## Terminal-Like Font

The page uses a terminal-first font stack: Menlo, Monaco, Cascadia Mono, DejaVu Sans Mono, Consolas, Liberation Mono, Courier New, then generic monospace. It also disables ligatures so code and terminal output feel closer to a real shell than an editor screenshot.

## Why This Instead Of VHS

VHS is great for real terminal demos, but rich interactive redraws can flicker in GIFs because the terminal is constantly clearing and repainting. This page uses Terminice's testing terminal to capture the actual ANSI output, emulates the visible terminal frame before cleanup, and displays that frame in the browser.

For real behavior demos, keep using VHS or screen recording. For README polish, package pages, and component docs, this visual demo gives cleaner screenshots and smoother short videos while still staying grounded in actual Terminice rendering.

## Regenerate Frames

Run this from the repo root after changing component rendering:

```text
dart --packages=terminice/.dart_tool/package_config.json terminice_visual_demo/generate.dart
```

The generator scripts input for every catalogue component, captures the raw terminal output, and rewrites `frames.js`.
