#import "@local/tuileur:0.1.0": tiler, use_tileset, palettes, make_palette

#set page(
  header: none,
  footer: none,
  height: auto,
  width: auto,
  margin: 0pt,
)

#tiler(
  cols: 5,
  rows: 5,
  tileset: use_tileset("Gibson"),
  colors: palettes.JetBrains,
)