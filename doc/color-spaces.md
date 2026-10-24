# Color spaces in mist

Reference for `mist/color/`: what each color space is, how mist scales it, and
how the conversions fit together. The color math is a port of
[go-colorful](https://github.com/lucasb-eyer/go-colorful), and the
profile-degradation logic is a port of
[termenv](https://github.com/muesli/termenv). When in doubt, compare against
those two.

## Layout

| Path | Contents |
|---|---|
| `mist/color/color.mojo` | `Color` enum (`ASCII`, `ANSI(UInt8)`, `ANSI256(UInt8)`, `RGB(UInt32)`), ANSI sequence output, profile degradation (`hex_to_ansi256`, `ansi256_to_ansi`), and every `to_*` / `from_*` / `distance_*` / `blend_*` method |
| `mist/color/math.mojo` | Constants (`D65`, `hSLuvD65`, `KAPPA`, `EPSILON`, the XYZ→RGB matrix) and helpers (`linearize`, `lab_f`, `xyz_to_uv`, `get_bounds`, `max_chroma_for_lh`, `interp_angle`, `in_range`) |
| `mist/color/spaces/*.mojo` | One plain struct per space (`RGB[linear]`, `xyz`, `xyY`, `Lab`, `hcl`, `Luv`, `LuvLCh`, `HSLuv`, `HPLuv`, `HSV`, `HSL`) plus the conversions out of that space |

`Color` is the only type the rest of the library touches. Style and profile code
just stores it and asks for an ANSI sequence. The space structs are a public API
for users who want color math, such as gradients and nearest-color search.

## Conversion graph

Every arrow is a method on the source struct. `Color.to_X()` walks the chain for
you.

```text
Color ──to_rgb──▶ RGB[linear=False] (sRGB) ──linearize──▶ RGB[linear=True] ──to_xyz──▶ xyz
                                                                                  │
                         ┌────────────────────────┬────────────────────────────────┤
                         ▼                        ▼                                ▼
                        xyY                     Lab ──to_hcl──▶ hcl            Luv ──to_LuvLCh──▶ LuvLCh
                                                                                                    │
                                                                            ┌───────────────────────┤
                                                                            ▼                       ▼
                                                                          HSLuv                   HPLuv
Color ──to_HSV──▶ HSV, Color ──to_hsl──▶ HSL  (computed straight from sRGB; not perceptual)
```

Every `Color.to_X` has a `Color.from_X` that takes either the components as
floats or the space's struct, so `Color.from_Lab(color.to_Lab())` works as well
as `Color.from_Lab(L, a, b)`. The struct overloads take the same keyword-only
`white_ref`, and `from_HSLuv` / `from_HPLuv` default to `hSLuvD65` like their
`to_` counterparts. HSLuv and HPLuv return to LCh(uv) through
`HSLuv.to_LuvLCh` / `HPLuv.to_LuvLCh`. All the perceptual spaces then go
back through `xyz → RGB[linear=True] → delinearize → Color`. Every one of
the 16.7M sRGB colors round-trips exactly through hcl, LuvLCh, HSLuv and HPLuv,
and the test suite checks the other spaces on sample colors.
Many coordinates in the perceptual spaces have **no sRGB equivalent**, so the
reverse path can produce linear RGB values (and negative XYZ, out-of-range a/b/u/v)
outside the gamut. `Color.from_rgb` clamps each channel to [0, 1] and rounds to
the nearest 8-bit value, so these land on the nearest edge of the gamut.

## Shared constants

| Constant | Value | Meaning |
|---|---|---|
| `D65` | (0.95047, 1.0, 1.08883) | CIE standard illuminant D65 white point, 2° observer, as XYZ with Y normalized to 1 |
| `hSLuvD65` | (0.95045592705167, 1.0, 1.089057750759878) | The D65 white HSLuv uses. It's derived from the sRGB matrix so that white maps to exactly L=1 and S=0 |
| `EPSILON` | 216/24389 ≈ 0.008856 | (6/29)³, where the CIE L* curve switches from linear to cube root |
| `KAPPA` | 24389/27 ≈ 903.3 | (29/3)³, the slope of the linear part of the CIE L* curve |
| sRGB gamma | decode: `v ≤ 0.04045 ? v/12.92 : ((v+0.055)/1.055)^2.4`<br>encode: `v ≤ 0.0031308 ? 12.92·v : 1.055·v^(1/2.4) − 0.055` | IEC 61966-2-1 transfer function |

## The spaces

**mist divides CIE coordinates by 100.** The published formulas use
L* ∈ [0, 100] and a*/b*/u*/v* in roughly ±100–200. mist stores all of them
divided by 100, following go-colorful, so L is always in [0, 1]. Any formula
taken from a paper or from Lindbloom must be scaled to match. `distance_cie94`
and `distance_ciede2000` multiply by 100 first and scale the result back down.

The "sRGB range" column below gives the extremes measured by sweeping the whole
sRGB cube through mist's own formulas (65³ samples). It's for reference, not a
limit: see [Range assertions](#range-assertions) for what the constructors check.

| Struct | Components (mist scale) | sRGB range | What it is |
|---|---|---|---|
| `RGB[linear=False]` | R, G, B ∈ [0, 1] | [0, 1] | Gamma-encoded sRGB, the values terminals and hex codes use. Not perceptually uniform, and averaging it darkens midpoints |
| `RGB[linear=True]` | R, G, B ∈ [0, 1] | [0, 1] for in-gamut colors | Linear light: proportional to physical intensity. Use it for physically correct mixing (`blend_linear_rgb`) and as the step to XYZ |
| `xyz` | x, y, z | x ≤ 0.9505, y ≤ 1.0, z ≤ 1.0891 | CIE 1931 XYZ, the device-independent hub that every other space converts through. Y is relative luminance |
| `xyY` | x, y chromaticity; Y luminance | all [0, 1] | XYZ split into chromaticity (x, y) and brightness (Y). For black, the white point's chromaticity is used |
| `Lab` | L ∈ [0, 1]; a, b | a ∈ [−0.862, 0.982], b ∈ [−1.079, 0.945] | CIE 1976 L\*a\*b\*. Roughly perceptually uniform: a is green↔red and b is blue↔yellow. Euclidean distance is CIE76 ΔE |
| `hcl` | h ∈ [0, 360); c; l ∈ [0, 1] | c ≤ 1.338 | Lab in polar form (CIE LCh(ab)): hue angle, chroma (√(a²+b²)) and lightness. Good for hue-preserving gradients |
| `Luv` | L ∈ [0, 1]; u, v | u ∈ [−0.831, 1.750], v ∈ [−1.341, 1.074] | CIE 1976 L\*u\*v\*. Same L as Lab, but chromaticity is based on u′v′, so additive mixtures of lights fall on straight lines |
| `LuvLCh` | L ∈ [0, 1]; C; h ∈ [0, 360) | C ≤ 1.790 | Luv in polar form (CIE LCh(uv)) |
| `HSLuv` | H ∈ [0, 360); S, L ∈ [0, 1] | S, L ∈ [0, 1] | [HSLuv](https://www.hsluv.org/): LCh(uv) with chroma rescaled so S=1 is the most saturated in-gamut color *for that L and H*. Every (H, S, L) is a valid sRGB color, but equal S doesn't mean equal colorfulness across hues |
| `HPLuv` | H ∈ [0, 360); P ≥ 0; L ∈ [0, 1] | P up to ≈18 near black | HSLuv's pastel variant. Chroma is rescaled by the largest chroma that is in gamut for *every* hue at that L, so equal P means equal chroma. Only P ≤ 1 is guaranteed in gamut; saturated colors give P > 1 |
| `HSV` | H ∈ [0, 360); S, V ∈ [0, 1] | [0, 1] | The usual hexcone model computed from gamma-encoded sRGB. Cheap and intuitive, but not perceptual (yellow at V=1 looks far brighter than blue at V=1) |
| `HSL` | H ∈ [0, 360); S, L ∈ [0, 1] | [0, 1] | The double-cone variant of HSV, also from gamma-encoded sRGB. Not to be confused with HSLuv |

### How HSLuv / HPLuv work

`get_bounds(L)` returns six lines in the u-v plane of LCh(uv): the places where
one of R, G or B reaches 0 or 1 at that lightness. Together they outline the
sRGB gamut at that L.

- **HSLuv:** `max_chroma_for_lh` casts a ray from the origin at angle H and
  returns the distance to the nearest line. That distance is the maximum chroma,
  and `S = C / max_chroma`.
- **HPLuv:** `max_safe_chroma_for_l` finds the shortest perpendicular distance
  from the origin to any line. That's the largest chroma that is in gamut for
  every hue, and `P = C / max_safe_chroma`.

The reference implementation works with L and C in [0, 100], so `LuvLCh.to_HSLuv`
and `to_HPLuv` multiply by 100 on the way in and divide on the way out.

## Distances and blends

| Method | Space | Notes |
|---|---|---|
| `distance_rgb` | sRGB | Fast, but a poor match for perception |
| `distance_linear_rgb` | linear RGB | Physical, not perceptual. Useful for dithering |
| `distance_riemersma` | sRGB, weighted | [compuphase "redmean"](https://www.compuphase.com/cmetric.htm). Cheap, and close to CIELUV in quality |
| `distance_lab` / `distance_cie76` | Lab | Euclidean ΔE\*ab. On mist's scale, 0.01 is about one just-noticeable difference |
| `distance_cie94` | Lab | CIE94 with graphic-arts weights (k1=0.045, k2=0.015) |
| `distance_ciede2000` / `…klch` | Lab | CIEDE2000, the most accurate and the most expensive. Profile degradation uses it. Checked against Sharma et al.'s reference pairs in `test/test_color_spaces.mojo` |
| `distance_Luv` | Luv | Euclidean ΔE\*uv |
| `distance_HSLuv` | HSLuv | Euclidean distance with the hue difference (wrapped to [0°, 180°]) divided by 100. termenv degrades with this; mist doesn't (see below) |
| `blend_linear_rgb`, `blend_Luv`, `blend_lab` | the named space | Linear interpolation of the components |
| `blend_hcl`, `blend_Luv_LCh` | polar spaces | L and C are interpolated linearly. Hue goes the short way round the circle via `interp_angle(a0, a1, t)`, which returns `a0` at t=0 and `a1` at t=1. `blend_hcl` borrows the other color's hue when one side is nearly gray (c ≤ 0.00015) |

Blends in the polar spaces often pass outside the sRGB gamut, for example red→blue in HCL. `from_rgb` clamps the result.

## Profile degradation

When a `Style`'s profile is lower than the color's type:

- **RGB → ANSI256** (`hex_to_ansi256`): returns the CIEDE2000-nearest of 11
  candidates. Eight are the xterm cube colors (levels
  `[0, 0x5f, 0x87, 0xaf, 0xd7, 0xff]`, indices 16–231) whose levels bracket each
  channel. Three are the gray ramp entries `8 + 10·i` (indices 232–255) nearest
  the input's lightness L\*. Ties go to the cube. The palette's Lab coordinates
  are precomputed in `ANSI256_LAB`, so each call converts only the input.
- **ANSI256 → ANSI** (`ansi256_to_ansi`): a precomputed lookup table
  (`ANSI256_TO_ANSI` in `_ansi_colors.mojo`) holding the CIEDE2000-nearest of the 16
  base colors, with ties going to the lower index. Its docstring has the recipe.
  Regenerate this table and `ANSI256_LAB` whenever `distance_ciede2000`, the
  Lab conversion or `ANSI_HEX_CODES` changes. A test checks `ANSI256_LAB`
  against the runtime conversion.
- **RGB → ANSI** goes through both steps: `hex_to_ansi256`, then the table.
- **→ ASCII**: no color is emitted at all.

## Range assertions

The space constructors `debug_assert` their inputs (active under
`-D ASSERT=all`, which `pixi run tests` uses). `in_range` allows 1e-9 of slack so
rounding at an exact edge (black's Lab L is −1.7e-17) still passes. What is
checked depends on whether out-of-gamut values can legitimately reach the
constructor:

| Struct | Checked | Why |
|---|---|---|
| `RGB[linear=False]`, `HSV`, `HSL`, `HSLuv`, `xyY` | every component in its documented range | Only built from sRGB or from user input |
| `HPLuv` | H, L in range, P ≥ 0 | P > 1 just means "not representable in HPLuv" |
| `RGB[linear=True]` | nothing | The step back from XYZ, where out-of-gamut values are expected |
| `xyz` | y (luminance) ∈ [0, 1] | x and z go negative when converting out-of-gamut Lab/Luv back |
| `Lab`, `Luv` | L ∈ [0, 1] | a/b/u/v exceed the sRGB range on the way back from polar blends and `from_hcl` / `from_LuvLCh` |
| `hcl`, `LuvLCh` | L ∈ [0, 1], chroma ≥ 0, hue ∈ [0, 360] | Same reason |

The sweep behind these choices: every conversion on a 17³ grid of colors that
includes the 255 corners (fast and accurate paths), five blend methods across
≈167k color pairs and t values, and round trips through eight spaces. All of it
passes with asserts on, and every round trip returns the exact input hex.

## Deviations from upstream

These are deliberate fixes, so don't "restore" them when comparing with the
reference code:

- **`distance_HSLuv` wraps the hue difference.** go-colorful and termenv
  subtract hues directly, so 2° and 359° score as 357° apart. With correct
  HSLuv, saturated reds near 0° score as far from each other as from a gray.
- **The ANSI256 gray ramp uses the average of the input's channels.** termenv
  averages the 0–5 cube indices instead, which makes the ramp almost
  unreachable. Now `#c0c0c0` → 250 and `#333333` → 236.
- **Profile degradation uses CIEDE2000, not HSLuv.** See the next section.
- **Polar hue is 0 only for grays.** go-colorful reports hue 0 whenever
  `|b − a|` or `|a|` (Luv: `|v − u|` or `|u|`) is below 1e-4. That zeroes the
  hue of saturated colors too: `#e0c060` (a strong yellow) and `#302010` came back
  from hcl / LuvLCh as different colors. mist zeroes the hue only when chroma is
  below 1e-3 × L, which catches sRGB grays (rounding chroma up to 3.7e-4 × L)
  while keeping the hue of near-blacks such as `#000001`.
- **`Color.from_rgb` clamps and rounds.** go-colorful leaves clamping to the
  caller and rounds in `Hex()`. mist quantizes at construction, so it does both
  there.

`get_bounds`, the blends and `blend_linear_rgb` now match go-colorful exactly.
HSLuv output matches the [hsluv.org](https://www.hsluv.org/) reference values
(see `test/test_color_spaces.mojo`).

## Degradation metric

termenv picks ANSI and ANSI256 colors by HSLuv distance. HSLuv rescales
saturation by the maximum chroma at each lightness, and near white that maximum
is tiny. So a pale pink such as `#ffdddd` has S ≈ 1 and lands nearer to bright
red (ΔE76 ≈ 100) than to white (ΔE76 ≈ 16). mist uses CIEDE2000 for both steps
instead.

termenv also compares only two ANSI256 candidates: the per-channel cube
quantization and one gray. Rounding each channel on its own can give the wrong
hue. `#993322` quantizes to `#875f00`, an olive, and a gray won (ΔE2000 25),
where 124 (`#af0000`) is far closer.

These are the mean errors from input to chosen color over a 16-step RGB grid
(4,096 colors):

| Profile | Metric | termenv (HSLuv, 2 candidates) | CIEDE2000, 2 candidates | CIEDE2000, 11 candidates (current) | Best possible |
|---|---|---|---|---|---|
| ANSI256 | ΔE2000 | 6.09 | 5.98 | 4.94 | 4.94 |
| ANSI | ΔE2000 | 16.30 | 14.88 | 14.13 | 13.63 |
| ANSI | ΔE76 | 44.44 | 35.67 | 34.62 | 27.70 |

The 11-candidate search isn't exhaustive. CIEDE2000 trades lightness against
chroma, so the nearest cube color is occasionally two levels away in a channel.
`#003778` picks 18 (`#000087`, ΔE2000 15.2) over 25 (`#005faf`, 14.1). On a
step-5 grid (148,877 colors), 0.85% of picks miss the exhaustive optimum, by
0.74 ΔE2000 on average and 4.8 at worst, which raises the overall mean by 0.006.
Repeatedly stepping one level along an axis cuts the misses to 0.2% but costs 43%
more per call. A full 3×3×3 neighbourhood would remove them, but measured
against exhaustive search it isn't worth it.

Measured cost per `hex_to_ansi256` call (built binary, Apple silicon): about
0.5 µs with two candidates and about 1.3 µs with 11.

The remaining ANSI gap comes from RGB → ANSI rounding twice, once to ANSI256 and
then to the 16 base colors. Searching the 16 base colors directly gives 13.63,
but it brings back the 16 distances per conversion that `ANSI256_TO_ANSI` was
introduced to avoid.

CIEDE2000 is discontinuous where two hues are exactly 180° apart. Sharma et
al.'s pair 6 sits on that boundary, and its published value depends on which way
floating-point rounding falls. The test suite checks the other reference pairs.

## Further reading

- go-colorful source and README, which explains the [0, 1] scaling: <https://github.com/lucasb-eyer/go-colorful>
- HSLuv math and reference implementations: <https://www.hsluv.org/math/>
- CIEDE2000 implementation notes, test data and reference code (Sharma, Wu & Dalal, 2005): <https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/>
- Bruce Lindbloom's conversion formulas and constants: <http://www.brucelindbloom.com/index.html?Math.html>
- CIELAB / CIELUV / CIEDE2000 on Wikipedia: <https://en.wikipedia.org/wiki/CIELAB_color_space>, <https://en.wikipedia.org/wiki/CIELUV>, <https://en.wikipedia.org/wiki/Color_difference>
- sRGB transfer function: <https://en.wikipedia.org/wiki/SRGB>
- Riemersma's "redmean" distance: <https://www.compuphase.com/cmetric.htm>
- termenv's color degradation: <https://github.com/muesli/termenv/blob/master/color.go>
