#import "../lib.typ": *

#set page(
  header: none,
  footer: none,
  margin: (x: auto, y: 0pt),
  background: rect(
    width: 100%,
    height: 100%
  )
)

#let args = (
  colors: (
    rgb("#000000"),
  ),
  cols: 5, rows: 5,
  stroke_width: 2,
  fill: false,
  background_colors: (rgb("c4b2d5"),),
)

#grid(
  columns: 4,
  gutter: 10pt,
  ..tileset_counts.keys()
  .map(
    n => [
      #tiler(
        tileset: use_tileset(n),
        ..args
      )
      #v(-10pt)
      #align(center)[ #n ]
    ]
  )
)