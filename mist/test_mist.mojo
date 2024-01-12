from mist import TerminalStyle
from mist.color import ANSIColor, ANSIColor256, RGB, hex_to_rgb



# fn main():
#     var style = TerminalStyle()
#     # style.background(ANSIColor256(33))
#     style.color(ANSIColor256(100))
#     style.invert()
#     style.crossout()
#     print(style.render("Hello World!"))

fn main() raises:
    # print(hex_to_rgb("ff0000").__str__())
    let value = String("#c9a0dc")
    let result = hex_to_rgb(value)
    print(result.__str__())