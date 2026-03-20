# VHS Tapes

This folder contains [VHS](https://github.com/charmbracelet/vhs) tapes used to generate the animated terminal GIFs for the `terminice` documentation.

## Generating GIFs

To re-generate the showcase GIF or any future GIFs, make sure you are in the root of the `terminice` package (not inside this `vhs` folder) and run:

```bash
# Run from the terminice/ directory
vhs vhs/showcase.tape
```

This ensures that the paths inside the tape (like `Output assets/showcase.gif` and `dart run example/showcase.dart`) resolve correctly.

## Requirements

You need `vhs` installed on your machine:
```bash
brew install vhs
```