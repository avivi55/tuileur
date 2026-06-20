#import "../lib.typ": tiler, use_tileset, palettes, make_palette


#figure(
  tiler(
    tileset: use_tileset("Benjamin"),
    cols: 20,
    rows: 7,
    colors: palettes.DataGrip,
    fill: false,
    background_colors: (black,),
    // stroke_width: 2,
    tile_scale: 1.2,

  ),
  caption: [Hyperspace]
)

#figure(
  tiler(
    tileset: use_tileset("Deleuze"),
    cols: 20,
    rows: 7,
    colors: palettes.RubyMine.map(c => c.transparentize(50%)),
    // fill: false,
    stroke: true,
    stroke_width: 1.5,
    background_colors: (rgb("#36174f"),),
    // stroke_width: 2,
    tile_scale: 2,
    perlin_colors: true,
    perlin_colors_scale: 8,
    seed: "RhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizomeRhizome"
  ),
  caption: [Rhizome]
)

#figure(
  tiler(
    tileset: use_tileset("Gombrich"),
    cols: 20,
    rows: 7,
    colors: palettes.JetBrains.map(c => c.transparentize(70%)),
    stroke: false,
    background_colors: (rgb("#ee3d7d"),),
    tile_scale: 3.5,
    // perlin_colors: true,
    // perlin_colors_scale: 8,
  ),
  caption: [Sunshine]
)
#figure(
  tiler(
    tileset: use_tileset("Lem"),
    cols: 20,
    rows: 7,
    colors: palettes.IntelliJ-IDEA.map(c => c.transparentize(50%)),
    stroke: true,
    background_colors: (rgb("#04305e"),),
    tile_scale: 2.3,
    perlin_colors: true,
    perlin_colors_scale: 5,
    seed: "r"
  ),
  caption: [Summer Blossom]
)
#figure(
  tiler(
    tileset: use_tileset("Guattari"),
    cols: 20,
    rows: 7,
    colors: palettes.PyCharm.map(c => c.transparentize(50%)),
    stroke: true,
    stroke_width: 1.5,
    background_colors: (rgb("#04305e"),),
    tile_scale: .99,
    perlin_colors: true,
    perlin_colors_scale: 2.5,
    seed: "dsdsssssssssddddssss"
  ),
  caption: [Imaginary Landscape]
)

#figure(
  tiler(
    tileset: use_tileset("King"),
    cols: 20,
    rows: 7,
    colors: make_palette(palettes.Space),
    stroke: true,
    stroke_width: 10,
    stroke_opacity: .5,
    background_colors: (rgb("#3a2865"),),
    tile_scale: .99,
    perlin_colors: true,
    perlin_colors_scale: 2.5,
    seed: "dsdsssssssssddddssss"
  ),
  caption: [City Lights]
)