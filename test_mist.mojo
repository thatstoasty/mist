from mist import TerminalStyle, Profile
from mist.color import ANSIColor, ANSI256Color, RGBColor
from mist.screen import cursor_forward, cursor_down, cursor_up, cursor_back, clear_line, clear_line_right

# fn main() raises:
#     let profile = Profile("TrueColor")
#     # degrading colors doesn't exactly work rn, I need to figure that out
#     # let text_color = profile.color[RGBColor]("#c9a0dc")
#     var style = TerminalStyle(profile)
#     # style.background(ANSI256Color(33))
#     style.foreground(RGBColor("#c9a0dc"))
#     style.foreground(style.profile.color("#c9a0dc"))
#     style.underline()
#     let styled = style.render("Hello World!")
#     print(styled)


fn main() raises:
    print_no_newline("hello")
    cursor_back(2)
    clear_line_right()
