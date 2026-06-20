#import "../lib.typ": *

#set page(
  header: none,
  footer: none,
  height: auto,
  width: auto,
  margin: 0pt,
)

#tiler(
  cols: 2,
  rows: 2,
  tileset: use_tileset("All"),
  colors: (white,),
  background_colors: (black,),
  tile_scale: 1.0,
  stroke_width: 4.0,
  fill_coef: 1.0,
  fill: false,
  stroke: true,
  perlin_stroke_width_scale: 0.1,
  seed: "0411",
)