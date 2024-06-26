from mist import TerminalStyle, Profile, new_style, TRUE_COLOR
from mist.color import ANSIColor, ANSI256Color, RGBColor


# Profile cannot query for the terminal profile at compile time. So it MUST be set.
alias profile = Profile(TRUE_COLOR)
alias true_color_style = new_style(profile)
alias bold = true_color_style.bold()
alias faint = true_color_style.faint()
alias italic = true_color_style.italic()
alias underline = true_color_style.underline()
alias crossout = true_color_style.crossout()

alias red = true_color_style.foreground(profile.color("#E88388"))
alias green = true_color_style.foreground(profile.color("#A8CC8C"))
alias yellow = true_color_style.foreground(profile.color("#DBAB79"))
alias blue = true_color_style.foreground(profile.color("#71BEF2"))
alias magenta = true_color_style.foreground(profile.color("#D290E4"))
alias cyan = true_color_style.foreground(profile.color("#66C2CD"))
alias gray = true_color_style.foreground(profile.color("#B9BFCA"))

alias red_background = true_color_style.background(profile.color("#E88388"))
alias green_background = true_color_style.background(profile.color("#A8CC8C"))
alias yellow_background = true_color_style.background(profile.color("#DBAB79"))
alias blue_background = true_color_style.background(profile.color("#71BEF2"))
alias magenta_background = true_color_style.background(profile.color("#D290E4"))
alias cyan_background = true_color_style.background(profile.color("#66C2CD"))
alias gray_background = true_color_style.background(profile.color("#B9BFCA"))


fn main():
    print(
        "\n\t",
        bold.render("bold"),
        faint.render("faint"),
        italic.render("italic"),
        underline.render("underline"),
        faint.render("faint"),
        crossout.render("crossout"),
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
