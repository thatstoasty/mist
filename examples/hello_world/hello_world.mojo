from mist import TerminalStyle, Profile, new_style
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn main():
    # Profile queries for the terminal profile at run time.
    var profile = Profile()
    var true_color_style = new_style(profile)

    var bold = true_color_style.bold()
    var faint = true_color_style.faint()
    var italic = true_color_style.italic()
    var underline = true_color_style.underline()
    var crossout = true_color_style.crossout()

    var red = true_color_style.foreground(profile.color("#E88388"))
    var green = true_color_style.foreground(profile.color("#A8CC8C"))
    var yellow = true_color_style.foreground(profile.color("#DBAB79"))
    var blue = true_color_style.foreground(profile.color("#71BEF2"))
    var magenta = true_color_style.foreground(profile.color("#D290E4"))
    var cyan = true_color_style.foreground(profile.color("#66C2CD"))
    var gray = true_color_style.foreground(profile.color("#B9BFCA"))

    var red_background = true_color_style.background(profile.color("#E88388"))
    var green_background = true_color_style.background(profile.color("#A8CC8C"))
    var yellow_background = true_color_style.background(profile.color("#DBAB79"))
    var blue_background = true_color_style.background(profile.color("#71BEF2"))
    var magenta_background = true_color_style.background(profile.color("#D290E4"))
    var cyan_background = true_color_style.background(profile.color("#66C2CD"))
    var gray_background = true_color_style.background(profile.color("#B9BFCA"))
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
