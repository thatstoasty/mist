"""Ported from https:#github.com/lucasb-eyer/go-colorful/blob/master/colors.go#L470"""

from mist.math import cube, clamp01, sq, pi, max_float64
from mist.color import RGB
import math


# For this part, we do as R's graphics.hcl does, not as wikipedia does.
# Or is it the same?
fn xyz_to_uv(x: Float64, y: Float64, z: Float64) -> (Float64, Float64):
    let denom = x + (15.0 * y) + (3.0 * z)
    var u: Float64
    var v: Float64

    if denom == 0.0:
        u = 0.0
        v = 0.0

        return u, v

    u = 4.0 * x / denom
    v = 9.0 * y / denom

    return u, v


fn Clamped(rgb: RGB) -> RGB:
    return RGB(clamp01(rgb.R), clamp01(rgb.G), clamp01(rgb.B))


fn LuvToXyzWhiteRef(
    l: Float64, u: Float64, v: Float64, wref: DynamicVector[Float64]
) -> (Float64, Float64, Float64):
    var y: Float64
    if l <= 0.08:
        y = wref[1] * l * 100.0 * 3.0 / 29.0 * 3.0 / 29.0 * 3.0 / 29.0
    else:
        y = wref[1] * cube((l + 0.16) / 1.16)

    var un: Float64 = 0
    var vn: Float64 = 0
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    var x: Float64 = 0
    var z: Float64 = 0
    if l != 0.0:
        var ubis = (u / (13.0 * l)) + un
        var vbis = (v / (13.0 * l)) + vn
        x = y * 9.0 * ubis / (4.0 * vbis)
        z = y * (12.0 - (3.0 * ubis) - (20.0 * vbis)) / (4.0 * vbis)
    else:
        x = 0.0
        y = 0.0

    return x, y, z


fn XyzToLinearRgb(x: Float64, y: Float64, z: Float64) -> (Float64, Float64, Float64):
    """Converts from CIE XYZ-space to Linear RGB space."""
    let r = (3.2409699419045214 * x) - (1.5373831775700935 * y) - (
        0.49861076029300328 * z
    )
    let g = (-0.96924363628087983 * x) + (1.8759675015077207 * y) + (
        0.041555057407175613 * z
    )
    let b = (0.055630079696993609 * x) - (0.20397695888897657 * y) + (
        1.0569715142428786 * z
    )

    return r, g, b


fn delinearize(v: Float64) -> Float64:
    if v <= 0.0031308:
        return 12.92 * v

    return 1.055 * (v ** (1.0 / 2.4)) - 0.055


fn LinearRgb(r: Float64, g: Float64, b: Float64) -> RGB:
    return RGB(delinearize(r), delinearize(g), delinearize(b))


fn lengthOfRayUntilIntersect(theta: Float64, x: Float64, y: Float64) -> Float64:
    return y / (math.sin(theta) - x * math.cos(theta))


# fn HSLuvToLuvLCh(h: Float64, s: Float64, l: Float64) -> (Float64, Float64, Float64):
#     var tmp_l: Float64 = l * 100.0
#     var tmp_s: Float64 = s * 100.0

#     var c: Float64
#     var max: Float64
#     if (l > 99.9999999 or l < 0.00000001):
#         c = 0.0
#     else:
#         max = maxChromaForLH(l, h)
#         c = max / 100.0 * s

# 	# c is [-100..100], but for LCh it's supposed to be almost [-1..1]
# 	return clamp01(l / 100.0), c / 100.0, h


fn LuvLChToLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    let H: Float64 = 0.01745329251994329576 * h  # Deg2Rad
    let u = c * math.cos(H)
    let v = c * math.sin(H)
    return l, u, v


fn hSLuvD65() -> DynamicVector[Float64]:
    var vector: DynamicVector[Float64] = DynamicVector[Float64]()
    vector.append(0.95045592705167)
    vector.append(1.0)
    vector.append(1.089057750759878)

    return vector


fn Xyz(x: Float64, y: Float64, z: Float64) -> RGB:
    let r: Float64
    let g: Float64
    let b: Float64

    r, g, b = XyzToLinearRgb(x, y, z)
    return LinearRgb(r, g, b)


# Generates a color by using data given in CIE L*u*v* space, taking
# into account a given reference white. (i.e. the monitor's white)
# L* is in [0..1] and both u* and v* are in about [-1..1]
fn LuvWhiteRef(l: Float64, u: Float64, v: Float64, wref: DynamicVector[Float64]) -> RGB:
    let x: Float64
    let y: Float64
    let z: Float64
    x, y, z = LuvToXyzWhiteRef(l, u, v, wref)

    return Xyz(x, y, z)


# Generates a color by using data given in LuvLCh space, taking
# into account a given reference white. (i.e. the monitor's white)
# h values are in [0..360], C and L values are in [0..1]
# fn LuvLChWhiteRef(l: Float64, c: Float64, h: Float64, wref: DynamicVector[Float64]) -> RGB:
#     var L: Float64
#     var u: Float64
#     var v: Float64

#     L, u, v = LuvLChToLuv(l, c, h)
#     return LuvWhiteRef(L, u, v, wref)


# # HSLuv creates a new RGB from values in the HSLuv color space.
# # Hue in [0..360], a Saturation [0..1], and a Luminance (lightness) in [0..1].
# #
# # The returned color values are clamped (using .Clamped), so this will never output
# # an invalid color.
# fn HSLuv(h: Float64, s: Float64, inout l: Float64) -> RGB:
# 	# HSLuv -> LuvLCh -> CIELUV -> CIEXYZ -> Linear RGB -> sRGB
#     var u: Float64
#     var v: Float64
#     l, u, v = LuvLChToLuv(HSLuvToLuvLCh(h, s, l))
#     return LinearRgb(XyzToLinearRgb(LuvToXyzWhiteRef(l, u, v, hSLuvD65))).Clamped()


fn LinearRgbToXyz(r: Float64, g: Float64, b: Float64) -> (Float64, Float64, Float64):
    let x: Float64 = 0.41239079926595948 * r + 0.35758433938387796 * g + 0.18048078840183429 * b
    let y: Float64 = 0.21263900587151036 * r + 0.71516867876775593 * g + 0.072192315360733715 * b
    let z: Float64 = 0.019330818715591851 * r + 0.11919477979462599 * g + 0.95053215224966058 * b

    return x, y, z


fn linearize(v: Float64) -> Float64:
    if v <= 0.04045:
        return v / 12.92

    let lhs: Float64 = (v + 0.055) / 1.055
    let rhs: Float64 = 2.4
    return lhs**rhs


# LinearRgb converts the color into the linear RGB space (see http://www.sjbrown.co.uk/2004/05/14/gamma-correct-rendering/).
fn LinearRgb(col: RGB) -> (Float64, Float64, Float64):
    let r: Float64
    let g: Float64
    let b: Float64

    r = linearize(col.R)
    g = linearize(col.G)
    b = linearize(col.B)
    return r, g, b


fn Xyz(col: RGB) -> (Float64, Float64, Float64):
    let r: Float64
    let g: Float64
    let b: Float64
    r, g, b = LinearRgb(col)

    let x: Float64
    let y: Float64
    let z: Float64
    x, y, z = LinearRgbToXyz(r, g, b)
    return x, y, z


fn XyzToLuvWhiteRef(
    x: Float64, y: Float64, z: Float64, wref: DynamicVector[Float64]
) -> (Float64, Float64, Float64):
    var l: Float64
    if y / wref[1] <= 6.0 / 29.0 * 6.0 / 29.0 * 6.0 / 29.0:
        l = y / wref[1] * (29.0 / 3.0 * 29.0 / 3.0 * 29.0 / 3.0) / 100.0
    else:
        l = 1.16 * math.cbrt(y / wref[1]) - 0.16

    let ubis: Float64
    let vbis: Float64
    ubis, vbis = xyz_to_uv(x, y, z)

    let un: Float64
    let vn: Float64
    un, vn = xyz_to_uv(wref[0], wref[1], wref[2])

    let u: Float64
    let v: Float64
    u = 13.0 * l * (ubis - un)
    v = 13.0 * l * (vbis - vn)

    return l, u, v


# Converts the given color to CIE L*u*v* space, taking into account
# a given reference white. (i.e. the monitor's white)
# L* is in [0..1] and both u* and v* are in about [-1..1]
fn LuvWhiteRef(col: RGB, wref: DynamicVector[Float64]) -> (Float64, Float64, Float64):
    var x: Float64
    var y: Float64
    var z: Float64
    x, y, z = Xyz(col)

    var l: Float64
    var u: Float64
    var v: Float64
    l, u, v = XyzToLuvWhiteRef(x, y, z, wref)
    return l, u, v


fn LuvToLuvLCh(L: Float64, u: Float64, v: Float64) -> (Float64, Float64, Float64):
    # Oops, floating point workaround necessary if u ~= v and both are very small (i.e. almost zero).
    var h: Float64
    if math.abs(v - u) > 1e-4 and math.abs(u) > 1e-4:
        h = math.mod(
            57.29577951308232087721 * math.atan2(v, u) + 360.0, 360.0
        )  # Rad2Deg
    else:
        h = 0.0

    let l = L
    let c = math.sqrt(sq(u) + sq(v))

    return l, c, h


fn LuvLChWhiteRef(
    col: RGB, wref: DynamicVector[Float64]
) -> (Float64, Float64, Float64):
    let l: Float64
    let u: Float64
    let v: Float64
    l, u, v = LuvWhiteRef(col, wref)

    return LuvToLuvLCh(l, u, v)


fn getBounds(l: Float64) -> DynamicVector[DynamicVector[Float64]]:
    var sub2: Float64
    let sub1 = (l + 16.0**3.0) / 1560896.0
    let epsilon = 0.0088564516790356308
    let kappa = 903.2962962962963

    var ret: DynamicVector[DynamicVector[Float64]] = DynamicVector[
        DynamicVector[Float64]
    ]()
    var ret1 = DynamicVector[Float64]()
    ret1.append(0)
    ret1.append(0)

    var ret2 = DynamicVector[Float64]()
    ret2.append(0)
    ret2.append(0)

    var ret3 = DynamicVector[Float64]()
    ret3.append(0)
    ret3.append(0)

    var ret4 = DynamicVector[Float64]()
    ret4.append(0)
    ret4.append(0)

    var ret5 = DynamicVector[Float64]()
    ret5.append(0)
    ret5.append(0)

    var ret6 = DynamicVector[Float64]()
    ret6.append(0)
    ret6.append(0)

    ret.append(ret1)
    ret.append(ret2)
    ret.append(ret3)
    ret.append(ret4)
    ret.append(ret5)
    ret.append(ret6)

    var m = DynamicVector[DynamicVector[Float64]]()
    var m1 = DynamicVector[Float64]()
    m1.append(3.2409699419045214)
    m1.append(-1.5373831775700935)
    m1.append(-0.49861076029300328)
    m.append(m1)

    var m2 = DynamicVector[Float64]()
    m2.append(-0.96924363628087983)
    m2.append(-0.96924363628087983)
    m2.append(0.041555057407175613)
    m.append(m2)

    var m3 = DynamicVector[Float64]()
    m3.append(0.055630079696993609)
    m3.append(-0.20397695888897657)
    m3.append(1.0569715142428786)
    m.append(m3)

    if sub1 > epsilon:
        sub2 = sub1
    else:
        sub2 = l / kappa

    for i in range(len(m)):
        var k = 0
        while k < 2:
            let top1 = (284517.0 * m[i][0] - 94839.0 * m[i][2]) * sub2
            let top2 = (
                838422.0 * m[i][2] + 769860.0 * m[i][1] + 731718.0 * m[i][0]
            ) * l * sub2 - 769860.0 * Float64(k) * l
            let bottom = (
                632260.0 * m[i][2] - 126452.0 * m[i][1]
            ) * sub2 + 126452.0 * Float64(k)
            ret[i * 2 + k][0] = top1 / bottom
            ret[i * 2 + k][1] = top2 / bottom
            k += 1

    return ret


fn maxChromaForLH(l: Float64, h: Float64) -> Float64:
    let hRad = h / 360.0 * pi() * 2.0
    var minLength = max_float64()
    let bounds = getBounds(l)

    for i in range(len(bounds)):
        let line = bounds[i]
        let length = lengthOfRayUntilIntersect(hRad, line[0], line[1])
        if length > 0.0 and length < minLength:
            minLength = length

    return minLength


fn LuvLChToHSLuv(l: Float64, c: Float64, h: Float64) -> (Float64, Float64, Float64):
    # [-1..1] but the code expects it to be [-100..100]
    var tmp_l: Float64 = l * 100.0
    var tmp_c: Float64 = c * 100.0

    var s: Float64
    var max: Float64
    if l > 99.9999999 or l < 0.00000001:
        s = 0.0
    else:
        max = maxChromaForLH(l, h)
        s = c / max * 100.0

    return h, clamp01(s / 100.0), clamp01(l / 100.0)


# HSLuv returns the Hue, Saturation and Luminance of the color in the HSLuv
# color space. Hue in [0..360], a Saturation [0..1], and a Luminance
# (lightness) in [0..1].
fn HSLuv(col: RGB) -> (Float64, Float64, Float64):
    """Order: sRGB -> Linear RGB -> CIEXYZ -> CIELUV -> LuvLCh -> HSLuv."""
    let wref: DynamicVector[Float64] = hSLuvD65()
    let l: Float64
    let c: Float64
    let h: Float64
    l, c, h = LuvLChWhiteRef(col, wref)

    return LuvLChToHSLuv(l, c, h)


fn DistanceHSLuv(c1: RGB, c2: RGB) -> Float64:
    let h1: Float64
    let s1: Float64
    let l1: Float64
    let h2: Float64
    let s2: Float64
    let l2: Float64

    h1, s1, l1 = HSLuv(c1)
    h2, s2, l2 = HSLuv(c2)

    return math.sqrt(sq((h1 - h2) / 100.0) + sq(s1 - s2) + sq(l1 - l2))
