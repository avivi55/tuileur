#import "../lib.typ": *
#let text = "tuileur"
#let tiles_margin = 2
#let tiles_style_parameters = (
  stroke: false,
  tileset: use_tileset("All"),
  colors: palettes.JetBrains,
  image_options: (width: auto, height: auto)
)

#set page(
  header: none,
  footer: none,
  height: auto,
  width: auto,
  margin: 0pt,
)

#let upper_text = upper(text)
#let letter_cols = upper_text.len()

#let get_letter_tile(letter) = {
  let unicode = letter.to-unicode()
  return (read("../tiles/Alphabet/tile" + str(unicode - 64)  + ".svg"),)
}

#let letter_parameters = (
  tile_scale: .65,
  cols: 1, rows: 1,
  stroke: false,
  seed: "a",
  colors: (blue,),
)

#let side_parameters = (
  cols: tiles_margin,
  rows: 2 * tiles_margin + 1,
  ..tiles_style_parameters
)

#let middle_parameters = (
  cols: letter_cols,
  rows: tiles_margin,
  ..tiles_style_parameters
)

#grid(
  columns: range(letter_cols + 2).map(n => auto),
  rows: range(3).map(n => auto),
  grid.cell(
    rowspan: 3,
    tiler(..side_parameters),
  ),
  grid.cell(
    colspan: letter_cols,
    tiler(..middle_parameters),
  ),
  grid.cell(
    rowspan: 3,
    tiler(..side_parameters),
  ),
  ..upper_text.codepoints().map(
    l => tiler(
      ..letter_parameters,
      tileset: get_letter_tile(l),
    )
  ),
  grid.cell(
    colspan: letter_cols,
    tiler(..middle_parameters),
  ),
)