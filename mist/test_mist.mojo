from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor, RGB, hex_to_rgb, ansi256_to_ansi


fn main() raises:
    let profile = Profile("TrueColor")
    # degrading colors doesn't exactly work rn, I need to figure that out
    # let text_color = profile.color[RGBColor]("#c9a0dc")
    var style = TerminalStyle()
    # style.background(ANSI256Color(33))
    style.color(RGBColor("#c9a0dc"))
    style.underline()
    print(style.render("Hello World!"))


# fn main() raises:
#     # print(hex_to_rgb("ff0000").__str__())
#     let result = ansi256_to_ansi(200)
#     print(result.value)
