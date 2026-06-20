<p align="center">
    <img src="./images/preview.png"/>
</p>

A somewhat random tiling engine heavily inspired by [Jetbrain's CAI Tiler](https://tiler.labs.jb.gg/).

_Find out more about Jetbrains's Tiler in their [blogpost](https://blog.jetbrains.com/blog/2021/06/16/art-of-tiling-and-mind-coalescence/)._

## Quick Start Example

```typst
#import "@local/tuileur:0.1.0": tiler, use_tileset, palettes
// or #import "@preview/tuileur:0.1.0": tiler, use_tileset, palettes

#tiler(
  cols: 5,
  rows: 5,
  tileset: use_tileset("Gibson"),
  colors: palettes.JetBrains,
)
```
<p align="center">
  <img src="./images/quick.svg" width=50%/>
</p>



## Capabilities & Examples
You can explore some more examples in the `examples/` folder.


## Contributing / Building Yourself

The engine is built in Zig 0.16.x.

To compile it to WASM, simply run:
```bash
zig build
```

To install it directly into your local Typst packages directory (so you can `#import "@local/tuiles:0.1.0"` anywhere):
```bash
zig build install-typst
```
*(Note: Requires Linux/Mac with bash installed for the symlink step)*