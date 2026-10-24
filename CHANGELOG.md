# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.4.0] - yyyy-mm-dd

### Breaking changes

- Requires Mojo 1.2.0.
- The color types are now one enum. `ANSIColor`, `ANSI256Color`, `RGBColor`,
  `NoColor`, `AnyColor` and the old `Color` trait are replaced by `Color`, with the
  cases `Color.ascii`, `Color.ansi(UInt8)`, `Color.ansi256(UInt8)` and
  `Color.rgb(UInt32)`. `Style.foreground(color=...)`, `Style.background(color=...)`,
  `Profile.color()` and `Profile.convert()` take or return `Color`.
  `Profile.convert_ansi256()` takes the `UInt8` index, and `Profile.convert_rgb()`
  takes a `Color`.
- `Profile` is now an enum. `Profile.TRUE_COLOR` is renamed `Profile.true_color`.
  The `Profile(UInt8)` constructor and the `==` / `<` comparisons are gone; use
  `match` instead.
- `mist.color` is now a package (`mist.color.color`, `mist.color.math`,
  `mist.color.spaces`). The private `mist._hue` module is removed: its conversions,
  distances and blends are now methods on `Color`, and its tuple results are now
  color-space structs (for example `hue.Color.lab()` → `Color.to_Lab()`, which
  returns a `Lab`).
- Colors degraded to the ANSI256 and ANSI profiles can change (see Changed).

### Added

- Public color-space structs in `mist.color`: `RGB[linear]`, `xyz`, `xyY`, `Lab`,
  `hcl`, `Luv`, `LuvLCh`, `HSLuv`, `HPLuv`, `HSV` and `HSL`. Each converts to its
  neighbours, and under `-D ASSERT=all` its constructors check component ranges.
- `Color.to_*` and `Color.from_*` for every space. Every `from_*` accepts either the
  components as floats or the struct, for example `Color.from_Lab(L, a, b)` or
  `Color.from_Lab(lab)`. `from_HSLuv` and `from_HPLuv` are new, backed by
  `HSLuv.to_LuvLCh` and `HPLuv.to_LuvLCh`.
- `Color.to_hsl()`, returning the new `HSL` struct.
- `Color.distance_*` and `Color.blend_*` methods: RGB, linear RGB, Riemersma,
  CIE76, CIE94, CIEDE2000, Luv and HSLuv distances, and blends in linear RGB, Lab,
  Luv, HCL and LCh(uv).
- `doc/color-spaces.md`, a reference for the color spaces, their scaling and
  ranges, profile degradation, and where mist departs from go-colorful and termenv.
- `AGENTS.md`, with notes for coding agents working on the repository.

### Changed

- Profile degradation uses CIEDE2000 instead of termenv's HSLuv distance, which
  rates pale colors as highly saturated. Tints such as `#ffdddd` now degrade to
  white rather than bright red. The `ANSI256_TO_ANSI` table is regenerated.
- RGB → ANSI256 picks the nearest of 11 candidates (the 2×2×2 cube colors around
  the input and the 3 grays nearest its lightness) instead of comparing one
  quantized cube color with one gray. Over a 16-step RGB grid the mean CIEDE2000
  error falls from 6.09 to 4.94 for ANSI256 and from 16.30 to 14.13 for ANSI, at
  about 1.3 µs per conversion instead of 0.5 µs.
- `Color.from_rgb(Float64, ...)` clamps each channel to [0, 1] and rounds to the
  nearest 8-bit value, so conversions back from the perceptual spaces round-trip
  exactly and out-of-gamut results land on the gamut's edge.
- The polar spaces (hcl, LuvLCh, HSLuv, HPLuv) report a hue of 0 only for grays.
- Benchmarks are updated for the Mojo 1.2.0 `std.benchmark` API. The plain
  `bench_render_*` benchmarks reuse one `Style` and measure rendering alone, so
  they aren't comparable with earlier results; the `*_profile_color` variants still
  build the style and convert its color on every iteration.

### Fixed

These fixes are in the color math ported from go-colorful and termenv:

- The HSLuv/HPLuv gamut bounds used `L + 16³` instead of `(L + 16)³`, which
  skewed every HSLuv and HPLuv saturation and the degradation choices built on them.
- The ANSI256 gray ramp averaged the 0–5 cube indices rather than channel values,
  so grays such as `#c0c0c0` degraded to cube colors instead of the gray ramp.
- `distance_HSLuv` didn't wrap hue around 360°, so hues of 2° and 359° scored as
  357° apart.
- `blend_LuvLCh` interpolated hue from the second color to the first.
- Converting to 8-bit truncated instead of rounding, so `#808080` → Lab → back gave
  `#7f7f7f`.
- The hcl and LuvLCh hue was zeroed for saturated colors whose a ≈ b or a ≈ 0
  (u ≈ v or u ≈ 0 for Luv), for example `#e0c060`.

## [0.1.11] - 2024-01-22

- Moved some of the logic to compile time to reduce runtime overhead.
- Switched `int_to_str` to just fetch a string from a lookup array. It's faster and simpler.
- Changed the internal value for the ANSI colors to be UInt8, to constrain the values to 0-255.
- Changed RGB Tuples from UInt32 to UInt8, to constrain the values to 0-255.

## [0.1.10] - 2024-12-21

- Update profile detection to include a few more terminals.

## [0.1.9] - 2024-12-17

- Remove `gojo` dependencies, any usage of `StringBuilder` now uses String streaming.
- Rendering functions now accept `SizedWritable` types, instead of just `String`.

## [0.1.8] - 2024-09-22

- Pull in null terminator fix from `gojo` library.

## [0.1.7] - 2024-09-21

- Switch to using `StringBuilder.consume()` to avoid copying data.

## [0.1.6] - 2024-09-17

- Pull in compability changes from `hue` library to minimize boilerplate conversion code.

## [0.1.4] - 2024-09-13

- First release with a changelog! Added rattler build and conda publish.
