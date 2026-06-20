#import "lib.typ": tiler, use_tileset, palettes, make_palette

#tiler(
  cols: 1,
  rows: 1,
  tileset: use_tileset("Lem"),
  colors: (black, blue),
  fill: false,
  stroke: true,
  perlin_colors: true,
  perlin_colors_scale: 20,
  perlin_stroke_width: true,
  perlin_stroke_width_scale: 2,
  stroke_width: 2,
  fade_direction: ltr,
  tile_scale: 1.0,
  seed: "gsfsdmfl",
  image_options: (width: 100%),
)


#tiler(
  cols: 16,
  rows: 6,
  tileset: use_tileset("Gibson"),
  colors: palettes.PyCharm,
  tile_scale: .5,
  background_colors: (rgb("#1a1a2e"),),
  fill_coef: 0.7,

  fade_direction: ttb,
  fade_start: 50%,
  fade_width: 90%,
  seed: "fade-demo",
  image_options: (width: 100%),
)

#tiler(
  cols: 10,
  rows: 10,
  tileset: use_tileset("Yu"),
  colors: make_palette(palettes.Kotlin, steps: 6),
  stroke_opacity: .5,
  fill: false,
  stroke_width: 3,
  tile_scale: .8,
  background_colors: (rgb("#ffffff"),),
  fill_coef: 0.8,
  seed: "fill-coef-demo",
  image_options: (width: 100%),
)