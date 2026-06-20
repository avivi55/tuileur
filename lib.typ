#import "@preview/datify:1.0.1": *
#let tiler_plugin = plugin("./tiler.wasm")
#let tiler_index = counter("tiler_index")

/// Tile counts per tileset (used by use_tileset)
#let tileset_counts = (
  ".NET": 7,
  All: 374,
  Alphabet: 26,
  Ashley: 12,
  Asimov: 3,
  Atwood: 56,
  Benjamin: 32,
  Cixin: 6,
  Clarke: 3,
  Dante: 3,
  Defoe: 3,
  Delany: 3,
  Deleuze: 5,
  Derleth: 3,
  Dickson: 3,
  Disch: 3,
  Douglas: 3,
  Drake: 2,
  Eliott: 3,
  Gibson: 56,
  Gombrich: 8,
  Guattari: 4,
  Guin: 20,
  Heinlein: 3,
  Kelly: 1,
  King: 16,
  Languages: 4,
  Lem: 10,
  Moorcock: 3,
  Moore: 3,
  Num3r: 10,
  Phondke: 3,
  Piercy: 3,
  Plante: 3,
  Pratchett: 3,
  Pratt: 3,
  Quinn: 3,
  Ride: 3,
  Robinson: 2,
  Roddenberry: 3,
  Ryman: 3,
  Sagan: 3,
  Sheckley: 3,
  Stephenson: 2,
  Tidhar: 3,
  Tiedemann: 3,
  Utley: 3,
  Verne: 1,
  Weir: 3,
  Wells: 6,
  Yu: 3,
)

#let tilesets = tileset_counts.keys()

/// Load a tileset by name from the tiles/ directory.
///
/// - name (str): Tileset name, e.g. "Wells", "Gibson", "Atwood"
/// - tiles_dir (str): Path to the tiles directory (default: "tiles")
/// -> array: Array of SVG bytes ready to pass as `tileset:` to `tiler()`
#let use_tileset(name, tiles_dir: "tiles") = {
  let count = tileset_counts.at(name, default: 0)
  assert(count > 0, message: "Unknown tileset \"" + name + "\". Available: " + tilesets.join(", "))
  return range(1, count + 1).map(i => read(tiles_dir + "/" + name + "/tile" + str(i) + ".svg"))
}

/// JetBrains product color palettes
#let palettes = (
  JetBrains: (rgb("#ed3d7d"), rgb("#7c59a4"), rgb("#fcee39")),
  Space: (rgb("#1eaafc"), rgb("#c64def"), rgb("#f05c44")),
  IntelliJ-IDEA: (rgb("#007efc"), rgb("#fe315d"), rgb("#f97a12")),
  PhpStorm: (rgb("#b345f1"), rgb("#765af8"), rgb("#ff318c")),
  PyCharm: (rgb("#21d789"), rgb("#fcf84a"), rgb("#07c3f2")),
  RubyMine: (rgb("#fe2857"), rgb("#fc801d"), rgb("#9039d0")),
  WebStorm: (rgb("#07c3f2"), rgb("#087cfa"), rgb("#fcf84a")),
  CLion: (rgb("#21d789"), rgb("#009ae5"), rgb("#ed358c")),
  DataGrip: (rgb("#22d88f"), rgb("#9775f8"), rgb("#ff318c")),
  AppCode: (rgb("#087cfa"), rgb("#07c3f2"), rgb("#21d789")),
  GoLand: (rgb("#0d7bf7"), rgb("#b74af7"), rgb("#3bea62")),
  ReSharper: (rgb("#c21456"), rgb("#e14ce3"), rgb("#fdbc2c")),
  Rider: (rgb("#c90f5e"), rgb("#077cfb"), rgb("#fdb60d")),
  TeamCity: (rgb("#0cb0f2"), rgb("#905cfb"), rgb("#3bea62")),
  YouTrack: (rgb("#0cb0f2"), rgb("#905cfb"), rgb("#ff318c")),
  Kotlin: (rgb("#7f52ff"), rgb("#e44857"), rgb("#c711e1")),
  DataSpell: (rgb("#087cfa"), rgb("#21d789"), rgb("#fcf84a")),
  Qodana: (rgb("#ff318c"), rgb("#fc801d"), rgb("#fcf84a")),
)

/// Build an interpolated palette from a list of base colors.
///
/// Generates `steps` evenly-spaced interpolated colors between each consecutive
/// pair, producing `(N - 1) * steps + 1` colors in total.
///
/// - base_colors (array): Two or more Typst color values
/// - steps (int): Interpolation steps per consecutive pair (default 4)
/// - space (str): Color mixing space passed to `color.mix` (default "oklab")
/// -> array: Expanded array of Typst colors
#let make_palette(base_colors, steps: 4, space: oklab) = {
  if base_colors.len() == 0 { return () }
  if base_colors.len() == 1 { return base_colors }
  let result = ()
  for i in range(base_colors.len() - 1) {
    let a = base_colors.at(i)
    let b = base_colors.at(i + 1)
    for step in range(steps) {
      result = result + (
        if step == 0 {
          a
        } else {
          color.mix((a, 100% - step / steps * 100%), (b, step / steps * 100%), space: space)
        },
      )
    }
  }
  result + (base_colors.last(),)
}

/// [INTERNAL] Get a semi unique seed for the document
#let get_compilation_seed() = {
  let headings = query(heading)
  let figures = query(figure)
  let equations = query(math.equation)
  let base_entropy = headings.len() * 31 + figures.len() * 37 + equations.len() * 41 + 12
  let today = datetime.today()
  let date_entropy = today.year() * 365 + today.ordinal()
  return calc.rem(base_entropy * 1009 + date_entropy, 100000)
}

/// Generate a tiled SVG artwork using JetBrains-style tile patterns via the WASM tiler.
///
/// - cols (int): Number of tile columns (default: 10)
/// - rows (int): Number of tile rows (default: 10)
/// - tileset (array): Array of SVG bytes or strings, e.g. from `use_tileset()` or `read()`
/// - colors (array): Typst color values used as the tile palette (default: JetBrains)
/// - tile_scale (float): 1.0 = fill cell exactly; <1 = smaller; >1 = overflows neighbours (default: 1.0)
/// - background_colors (array): Per-cell background colors picked randomly (default: ())
/// - stroke_width (float): Base stroke width applied to elements (default: 1.0)
/// - fill_coef (float): Probability [0,1] that each tile is rendered filled (default: 1.0)
/// - fill (bool): If true, assigns palette colors to the `fill` attribute of SVGs (default: true)
/// - stroke (bool): If true, assigns palette colors to the `stroke` attribute of SVGs (default: true)
/// - perlin_colors (bool): If true, distributes palette colors using smooth 3D Perlin noise (default: false)
/// - perlin_stroke_width (bool): If true, dynamically varies stroke widths using Perlin noise (default: false)
/// - perlin_colors_scale (float): Frequency/zoom scale for the color Perlin noise field (default: 0.1)
/// - perlin_stroke_width_scale (float): Frequency/zoom scale for the stroke width Perlin noise field (default: 0.1)

/// - fade_direction (direction | none): Fade axis — `ltr`, `rtl`, `ttb`, `btt`, or `none`
/// - fade_start (ratio): Position where fade begins; before this = full opacity (default: 50%)
/// - fade_width (ratio): Width of the fade zone from full to zero opacity (default: 50%)
/// - seed (none | int | str): RNG seed; auto-generated from document structure if `none`
/// - image_options (dict): Extra named args forwarded to `image.decode()` (e.g. `width`, `height`)
/// -> content: Rendered tiled image containing the output SVG
#let tiler(
  cols: 10,
  rows: 10,
  tileset: (),
  colors: (rgb("#ed3d7d"), rgb("#7c59a4"), rgb("#fcee39")),
  tile_scale: 1.0,
  background_colors: (),
  stroke_width: 1.0,
  fill_coef: 1.0,
  fill: true,
  stroke: true,
  perlin_colors: false,
  perlin_stroke_width: false,
  perlin_colors_scale: 0.1,
  perlin_stroke_width_scale: 0.1,

  stroke_opacity: 1.0,
  fade_direction: none,
  fade_start: 50%,
  fade_width: 50%,
  seed: none,
  image_options: (:),
) = context {
  tiler_index.step()

  let final_seed = if seed == none {
    str(calc.rem(
      get_compilation_seed() * 7919 + tiler_index.get().at(0) * 43227,
      1000000,
    ))
  } else {
    str(seed)
  }

  let tile_strings   = tileset.map(t => str(t))
  let color_hexes    = colors.map(c => c.to-hex())
  let bg_color_hexes = background_colors.map(c => c.to-hex())

  let fade_dir_str = ""
  if fade_direction != none {
    fade_dir_str = repr(fade_direction)
  }

  let svg_bytes = tiler_plugin.tiler(
    cbor.encode(cols),
    cbor.encode(rows),
    cbor.encode(tile_strings),
    cbor.encode(color_hexes),
    cbor.encode(bg_color_hexes),
    cbor.encode(float(stroke_width)),
    cbor.encode(fill_coef),
    cbor.encode(fill),
    cbor.encode(stroke),
    cbor.encode(perlin_colors),
    cbor.encode(perlin_stroke_width),
    cbor.encode(float(perlin_colors_scale)),
    cbor.encode(float(perlin_stroke_width_scale)),

    cbor.encode(float(stroke_opacity)),
    cbor.encode(fade_dir_str),
    cbor.encode(fade_start / 100%),
    cbor.encode(fade_width / 100%),
    cbor.encode(float(tile_scale)),
    cbor.encode(final_seed),
  )
  
  // We make them artifact for PDF/UA support, they do not convey any meaning, it is only decorative
  pdf.artifact(image(
    svg_bytes,
    format: "svg",
    alt: "",
    ..image_options,
  ))
}
