import mist
from mist import Profile


comptime true_color_style = mist.Style(Profile.TRUE_COLOR)

comptime bold = true_color_style.bold()
comptime faint = true_color_style.faint()
comptime italic = true_color_style.italic()
comptime underline = true_color_style.underline()
comptime strikethrough = true_color_style.strikethrough()

comptime red = true_color_style.foreground(0xE88388)
comptime green = true_color_style.foreground(0xA8CC8C)
comptime yellow = true_color_style.foreground(0xDBAB79)
comptime blue = true_color_style.foreground(0x71BEF2)
comptime magenta = true_color_style.foreground(0xD290E4)
comptime cyan = true_color_style.foreground(0x66C2CD)
comptime gray = true_color_style.foreground(0xB9BFCA)

comptime red_background = true_color_style.background(0xE88388)
comptime green_background = true_color_style.background(0xA8CC8C)
comptime yellow_background = true_color_style.background(0xDBAB79)
comptime blue_background = true_color_style.background(0x71BEF2)
comptime magenta_background = true_color_style.background(0xD290E4)
comptime cyan_background = true_color_style.background(0x66C2CD)
comptime gray_background = true_color_style.background(0xB9BFCA)


fn main():
    print(
        "\n\t",
        bold.render("bold"),
        faint.render("faint"),
        italic.render("italic"),
        underline.render("underline"),
        strikethrough.render("strikethrough"),
        end="",
    )

    print(
        "\n\t",
        red.render("red"),
        green.render("green"),
        yellow.render("yellow"),
        blue.render("blue"),
        magenta.render("magenta"),
        cyan.render("cyan"),
        gray.render("gray"),
        end="",
    )

    print(
        "\n\t",
        red_background.render("red"),
        green_background.render("green"),
        yellow_background.render("yellow"),
        blue_background.render("blue"),
        magenta_background.render("magenta"),
        cyan_background.render("cyan"),
        gray_background.render("gray"),
        "\n\n",
        end="",
    )
