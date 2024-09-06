from .style import Style
from .profile import Profile


alias RED = 0xE88388
alias GREEN = 0xA8CC8C
alias YELLOW = 0xDBAB79
alias BLUE = 0x71BEF2
alias MAGENTA = 0xD290E4
alias CYAN = 0x66C2CD
alias GRAY = 0xB9BFCA


# Convenience functions for quick style application
fn render_as_color(text: String, color: UInt32, profile: Int = -1) -> String:
    if profile == -1:
        return Style().foreground(color).render(text)
    return Style(profile).foreground(color).render(text)


fn red(text: String, profile: Int = -1) -> String:
    """Apply red color to the text."""
    return render_as_color(text, RED)


fn green(text: String, profile: Int = -1) -> String:
    """Apply green color to the text."""
    return render_as_color(text, GREEN, profile)


fn yellow(text: String, profile: Int = -1) -> String:
    """Apply yellow color to the text."""
    return render_as_color(text, YELLOW, profile)


fn blue(text: String, profile: Int = -1) -> String:
    """Apply blue color to the text."""
    return render_as_color(text, BLUE, profile)


fn magenta(text: String, profile: Int = -1) -> String:
    """Apply magenta color to the text."""
    return render_as_color(text, MAGENTA, profile)


fn cyan(text: String, profile: Int = -1) -> String:
    """Apply cyan color to the text."""
    return render_as_color(text, CYAN, profile)


fn gray(text: String, profile: Int = -1) -> String:
    """Apply gray color to the text."""
    return render_as_color(text, GRAY, profile)


fn render_with_background_color(text: String, color: UInt32, profile: Int = -1) -> String:
    if profile == -1:
        return Style().background(color).render(text)
    return Style(profile).background(color).render(text)


fn red_background(text: String, profile: Int = -1) -> String:
    """Apply red background color to the text."""
    return render_with_background_color(text, RED, profile)


fn green_background(text: String, profile: Int = -1) -> String:
    """Apply green background color to the text."""
    return render_with_background_color(text, GREEN, profile)


fn yellow_background(text: String, profile: Int = -1) -> String:
    """Apply yellow background color to the text."""
    return render_with_background_color(text, YELLOW, profile)


fn blue_background(text: String, profile: Int = -1) -> String:
    """Apply blue background color to the text."""
    return render_with_background_color(text, BLUE, profile)


fn magenta_background(text: String, profile: Int = -1) -> String:
    """Apply magenta background color to the text."""
    return render_with_background_color(text, MAGENTA, profile)


fn cyan_background(text: String, profile: Int = -1) -> String:
    """Apply cyan background color to the text."""
    return render_with_background_color(text, CYAN, profile)


fn gray_background(text: String, profile: Int = -1) -> String:
    """Apply gray background color to the text."""
    return render_with_background_color(text, GRAY, profile)


fn bold(text: String, profile: Int = -1) -> String:
    if profile == -1:
        return Style().bold().render(text)
    return Style(profile).bold().render(text)


fn faint(text: String, profile: Int = -1) -> String:
    if profile == -1:
        return Style().faint().render(text)
    return Style(profile).faint().render(text)


fn italic(text: String, profile: Int = -1) -> String:
    if profile == -1:
        return Style().italic().render(text)
    return Style(profile).italic().render(text)


fn underline(text: String, profile: Int = -1) -> String:
    if profile == -1:
        return Style().underline().render(text)
    return Style(profile).underline().render(text)


fn overline(text: String, profile: Int = -1) -> String:
    if profile == -1:
        return Style().overline().render(text)
    return Style(profile).overline().render(text)


fn crossout(text: String, profile: Int = -1) -> String:
    if profile == -1:
        return Style().crossout().render(text)
    return Style(profile).crossout().render(text)
