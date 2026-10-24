from std import testing
from std.testing import TestSuite

from mist.color import Color, Lab, ansi256_to_ansi, hex_to_ansi256
from mist._ansi_colors import ANSI256_LAB, ANSI_HEX_CODES
from mist._utils import lut
from mist.color.color import _ciede2000
from mist.profile import Profile


def _assert_close(got: Float64, expected: Float64, tolerance: Float64 = 1e-3) raises:
    testing.assert_true(abs(got - expected) <= tolerance, String("expected ", expected, ", got ", got))


def test_to_hsluv_is_perceptual() raises:
    # Plain HSL and HSLuv disagree on #3366cc; `to_HSLuv` must return HSLuv.
    var color = Color.rgb(0x3366CC)
    var hsluv = color.to_HSLuv()
    _assert_close(hsluv.H, 257.681)
    _assert_close(hsluv.S, 0.8458)
    _assert_close(hsluv.L, 0.4503)

    var hsl = color.to_hsl()
    _assert_close(hsl.H, 220.0)
    _assert_close(hsl.S, 0.6)
    _assert_close(hsl.L, 0.5)


def test_hsluv_reference_values() raises:
    # Pure sRGB primaries, from the hsluv.org reference implementation.
    var red = Color.rgb(0xFF0000).to_HSLuv()
    _assert_close(red.H, 12.177, 1e-2)
    _assert_close(red.S, 1.0)
    _assert_close(red.L, 0.5324)

    var blue = Color.rgb(0x0000FF).to_HSLuv()
    _assert_close(blue.H, 265.874, 1e-2)
    _assert_close(blue.S, 1.0)
    _assert_close(blue.L, 0.3230)


def test_round_trips_are_exact() raises:
    # Includes colors whose hue go-colorful's workaround zeroed (#302010: u ~= v,
    # #e0c060: a ~= 0) and a near-black whose chroma is tiny but whose hue is not.
    for value in [0x000000, 0x000001, 0x808080, 0x3366CC, 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFFFF, 0xC9A0DC, 0x302010, 0xE0C060]:
        var color = Color.rgb(UInt32(value))
        var hex = color.to_hex()
        var x = color.to_xyz()
        testing.assert_equal(Color.from_xyz(x).to_hex(), hex)
        testing.assert_equal(Color.from_xyz(x.x, x.y, x.z).to_hex(), hex)
        var xyy = color.to_xyY()
        testing.assert_equal(Color.from_xyY(xyy).to_hex(), hex)
        testing.assert_equal(Color.from_xyY(xyy.x, xyy.y, xyy.Y).to_hex(), hex)
        var lab = color.to_Lab()
        testing.assert_equal(Color.from_Lab(lab).to_hex(), hex)
        testing.assert_equal(Color.from_Lab(lab.L, lab.a, lab.b).to_hex(), hex)
        var hcl = color.to_hcl()
        testing.assert_equal(Color.from_hcl(hcl).to_hex(), hex)
        testing.assert_equal(Color.from_hcl(hcl.h, hcl.c, hcl.l).to_hex(), hex)
        var luv = color.to_Luv()
        testing.assert_equal(Color.from_Luv(luv).to_hex(), hex)
        testing.assert_equal(Color.from_Luv(luv.L, luv.u, luv.v).to_hex(), hex)
        var lch = color.to_LuvLCh()
        testing.assert_equal(Color.from_LuvLCh(lch).to_hex(), hex)
        testing.assert_equal(Color.from_LuvLCh(lch.L, lch.C, lch.h).to_hex(), hex)
        var hsluv = color.to_HSLuv()
        testing.assert_equal(Color.from_HSLuv(hsluv).to_hex(), hex)
        testing.assert_equal(Color.from_HSLuv(hsluv.H, hsluv.S, hsluv.L).to_hex(), hex)
        var hpluv = color.to_HPLuv()
        testing.assert_equal(Color.from_HPLuv(hpluv).to_hex(), hex)
        testing.assert_equal(Color.from_HPLuv(hpluv.H, hpluv.P, hpluv.L).to_hex(), hex)
        var hsv = color.to_HSV()
        testing.assert_equal(Color.from_hsv(hsv).to_hex(), hex)
        testing.assert_equal(Color.from_hsv(hsv.H, hsv.S, hsv.V).to_hex(), hex)
        var hsl = color.to_hsl()
        testing.assert_equal(Color.from_hsl(hsl).to_hex(), hex)
        testing.assert_equal(Color.from_hsl(hsl.H, hsl.S, hsl.L).to_hex(), hex)


def test_polar_hue() raises:
    # Saturated colors keep their hue; grays report 0 despite rounding chroma.
    _assert_close(Color.rgb(0xE0C060).to_hcl().h, 89.996, 1e-2)
    _assert_close(Color.rgb(0x302010).to_LuvLCh().h, 45.014, 1e-2)
    for value in range(256):
        var gray = Color.from_rgb(UInt8(value), UInt8(value), UInt8(value))
        testing.assert_equal(gray.to_hcl().h, 0.0)
        testing.assert_equal(gray.to_LuvLCh().h, 0.0)


def test_from_hsluv_reference_values() raises:
    # Inverses of the hsluv.org reference values in `test_hsluv_reference_values`.
    testing.assert_equal(Color.from_HSLuv(12.177, 1.0, 0.53241).to_hex(), 0xFF0000)
    testing.assert_equal(Color.from_HSLuv(265.874, 1.0, 0.32297).to_hex(), 0x0000FF)
    testing.assert_equal(Color.from_HSLuv(0.0, 0.0, 1.0).to_hex(), 0xFFFFFF)
    # HPLuv saturation above 1 is outside the gamut for that lightness; the result clamps.
    testing.assert_true(Color.from_HPLuv(12.177, 3.0, 0.53241).to_hex() <= 0xFFFFFF)


def test_from_rgb_rounds_and_clamps() raises:
    testing.assert_equal(Color.from_rgb(0.5, 0.5, 0.5).to_hex(), 0x808080)
    testing.assert_equal(Color.from_rgb(-0.25, 1.5, 0.0).to_hex(), 0x00FF00)


def test_blend_endpoints() raises:
    var red = Color.rgb(0xFF0000)
    var teal = Color.rgb(0x006666)
    for t in [0.0, 1.0]:
        var expected = red.to_hex() if t == 0.0 else teal.to_hex()
        testing.assert_equal(red.blend_linear_rgb(teal, t).to_hex(), expected)
        testing.assert_equal(red.blend_Luv(teal, t).to_hex(), expected)
        testing.assert_equal(red.blend_lab(teal, t).to_hex(), expected)
        testing.assert_equal(red.blend_hcl(teal, t).to_hex(), expected)
        testing.assert_equal(red.blend_LuvLCh(teal, t).to_hex(), expected)


def test_polar_blends_stay_in_gamut_and_move_hue() raises:
    # Red to blue in a polar space leaves the sRGB gamut midway; the result must
    # still be a valid 24-bit color, and its hue must lie between the two.
    var red = Color.rgb(0xFF0000)
    var blue = Color.rgb(0x0000FF)
    for t in [0.25, 0.5, 0.75]:
        var hcl = red.blend_hcl(blue, t)
        var lch = red.blend_LuvLCh(blue, t)
        testing.assert_true(hcl.to_hex() <= 0xFFFFFF)
        testing.assert_true(lch.to_hex() <= 0xFFFFFF)
        # Neither stays red: the hue moves toward blue through magenta.
        testing.assert_true(hcl.to_rgb().B > 0.2)
        testing.assert_true(lch.to_rgb().B > 0.2)


def test_hsluv_distance_wraps_hue() raises:
    # Hues 2.5 and 359 degrees are 3.5 degrees apart, not 356.5.
    var pink = Color.rgb(0xDD0055)
    testing.assert_true(pink.distance_HSLuv(Color.rgb(0xD7005F)) < 0.1)


def _check_ciede2000(l1: Float64, a1: Float64, b1: Float64, l2: Float64, a2: Float64, b2: Float64, expected: Float64) raises:
    # Reference data is on the CIE scale; mist stores L*a*b* divided by 100.
    var first = Lab(l1 / 100.0, a1 / 100.0, b1 / 100.0)
    var second = Lab(l2 / 100.0, a2 / 100.0, b2 / 100.0)
    _assert_close(_ciede2000(first, second) * 100.0, expected, 1e-4)
    _assert_close(_ciede2000(second, first) * 100.0, expected, 1e-4)


def test_ciede2000_reference_pairs() raises:
    # From Sharma, Wu & Dalal (2005), "The CIEDE2000 Color-Difference Formula:
    # Implementation Notes, Supplementary Test Data, and Mathematical Observations".
    # Pair 6 is omitted: its hues are exactly 180 degrees apart, where the formula is
    # discontinuous, and the published value depends on which way rounding falls.
    _check_ciede2000(50.0, 2.6772, -79.7751, 50.0, 0.0, -82.7485, 2.0425)
    _check_ciede2000(50.0, 3.1571, -77.2803, 50.0, 0.0, -82.7485, 2.8615)
    _check_ciede2000(50.0, 0.0, 0.0, 50.0, -1.0, 2.0, 2.3669)
    _check_ciede2000(50.0, 2.49, -0.001, 50.0, -2.49, 0.0009, 7.1792)
    _check_ciede2000(50.0, 2.49, -0.001, 50.0, -2.49, 0.0011, 7.2195)
    _check_ciede2000(50.0, 2.5, 0.0, 50.0, 0.0, -2.5, 4.3065)
    _check_ciede2000(50.0, 2.5, 0.0, 73.0, 25.0, -18.0, 27.1492)
    _check_ciede2000(60.2574, -34.0099, 36.2677, 60.4626, -34.1751, 39.4387, 1.2644)
    _check_ciede2000(22.7233, 20.0904, -46.694, 23.0331, 14.973, -42.5619, 2.0373)
    _check_ciede2000(2.0776, 0.0795, -1.135, 0.9033, -0.0636, -0.5514, 0.9082)


def test_hex_to_ansi256() raises:
    # Grays reach the gray ramp rather than the nearest cube gray.
    testing.assert_equal(hex_to_ansi256(Color.rgb(0xC0C0C0)), 250)
    testing.assert_equal(hex_to_ansi256(Color.rgb(0x333333)), 236)
    testing.assert_equal(hex_to_ansi256(Color.rgb(0x444444)), 238)
    # Exact cube colors map to themselves.
    testing.assert_equal(hex_to_ansi256(Color.rgb(0xFF0000)), 196)
    testing.assert_equal(hex_to_ansi256(Color.rgb(0x5F87AF)), 67)
    # Saturated reds whose hue straddles 0 degrees stay red.
    testing.assert_equal(hex_to_ansi256(Color.rgb(0xDD0055)), 161)
    # Quantizing each channel alone gives #875f00, an olive; the box search finds red.
    testing.assert_equal(hex_to_ansi256(Color.rgb(0x993322)), 124)


def test_ansi256_lab_table_matches_conversion() raises:
    for index in range(256):
        var lab = Color.rgb(lut[ANSI_HEX_CODES](index)).to_Lab()
        testing.assert_equal(lut[ANSI256_LAB](index * 3), lab.L)
        testing.assert_equal(lut[ANSI256_LAB](index * 3 + 1), lab.a)
        testing.assert_equal(lut[ANSI256_LAB](index * 3 + 2), lab.b)


def test_hex_to_ansi256_is_near_optimal() raises:
    # Against an exhaustive search of all 240 non-system colors, the 11-candidate
    # search may miss by a little on rare colors but not on average.
    var palette = List[Lab]()
    for index in range(256):
        palette.append(Color.rgb(lut[ANSI_HEX_CODES](index)).to_Lab())

    var total_gap = 0.0
    var count = 0
    for r in range(0, 256, 51):
        for g in range(0, 256, 51):
            for b in range(0, 256, 51):
                var color = Color.from_rgb(UInt8(r), UInt8(g), UInt8(b))
                var lab = color.to_Lab()
                var best = _ciede2000(lab, palette[16])
                for index in range(17, 256):
                    best = min(best, _ciede2000(lab, palette[index]))
                total_gap += _ciede2000(lab, palette[Int(hex_to_ansi256(color))]) - best
                count += 1
    # 0.01 CIE units of mean error, on mist's scale.
    testing.assert_true(total_gap / Float64(count) < 0.0001, String("mean gap ", total_gap / Float64(count)))


def test_ansi256_to_ansi_table() raises:
    for value in range(16):
        testing.assert_equal(ansi256_to_ansi(UInt8(value)), UInt8(value))
    for value in range(256):
        testing.assert_true(ansi256_to_ansi(UInt8(value)) < 16)
    testing.assert_equal(ansi256_to_ansi(196), 9)  # #ff0000 -> bright red
    testing.assert_equal(ansi256_to_ansi(160), 9)  # #d70000 -> bright red, not maroon
    testing.assert_equal(ansi256_to_ansi(224), 15)  # #ffd7d7 -> white, not bright red
    testing.assert_equal(ansi256_to_ansi(238), 0)  # #444444 -> black
    testing.assert_equal(ansi256_to_ansi(232), 0)  # #080808 -> black
    testing.assert_equal(ansi256_to_ansi(255), 15)  # #eeeeee -> white


def test_pale_tints_degrade_to_white() raises:
    # HSLuv rates these as fully saturated; by CIEDE2000 they are nearest white.
    comptime profile = Profile.ansi
    for value in [0xFFDDDD, 0xEECCDD, 0xFFDDCC]:
        testing.assert_equal(profile.convert(Color.rgb(UInt32(value))).to_hex_str(), Color.ansi(15).to_hex_str())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
