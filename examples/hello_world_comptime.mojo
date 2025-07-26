import mist
from mist import Profile


alias true_color_style = mist.Style(Profile.TRUE_COLOR)

alias bold = true_color_style.bold()
alias faint = true_color_style.faint()
alias italic = true_color_style.italic()
alias underline = true_color_style.underline()
alias strikethrough = true_color_style.strikethrough()

alias red = true_color_style.foreground(0xE88388)
alias green = true_color_style.foreground(0xA8CC8C)
alias yellow = true_color_style.foreground(0xDBAB79)
alias blue = true_color_style.foreground(0x71BEF2)
alias magenta = true_color_style.foreground(0xD290E4)
alias cyan = true_color_style.foreground(0x66C2CD)
alias gray = true_color_style.foreground(0xB9BFCA)

alias red_background = true_color_style.background(0xE88388)
alias green_background = true_color_style.background(0xA8CC8C)
alias yellow_background = true_color_style.background(0xDBAB79)
alias blue_background = true_color_style.background(0x71BEF2)
alias magenta_background = true_color_style.background(0xD290E4)
alias cyan_background = true_color_style.background(0x66C2CD)
alias gray_background = true_color_style.background(0xB9BFCA)


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
