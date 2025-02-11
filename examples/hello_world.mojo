import mist


fn main():
    # Profile queries for the terminal profile at run time.
    var true_color_style = mist.Style()

    var bold = true_color_style.bold()
    var faint = true_color_style.faint()
    var italic = true_color_style.italic()
    var underline = true_color_style.underline()
    var strikethrough = true_color_style.strikethrough()

    var red = true_color_style.foreground(0xE88388)
    var green = true_color_style.foreground(0xA8CC8C)
    var yellow = true_color_style.foreground(0xDBAB79)
    var blue = true_color_style.foreground(0x71BEF2)
    var magenta = true_color_style.foreground(0xD290E4)
    var cyan = true_color_style.foreground(0x66C2CD)
    var gray = true_color_style.foreground(0xB9BFCA)

    var red_background = true_color_style.background(0xE88388)
    var green_background = true_color_style.background(0xA8CC8C)
    var yellow_background = true_color_style.background(0xDBAB79)
    var blue_background = true_color_style.background(0x71BEF2)
    var magenta_background = true_color_style.background(0xD290E4)
    var cyan_background = true_color_style.background(0x66C2CD)
    var gray_background = true_color_style.background(0xB9BFCA)
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
