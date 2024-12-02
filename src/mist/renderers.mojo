from .style import Style, SizedWritable
from .profile import Profile


alias RED = 0xE88388
alias GREEN = 0xA8CC8C
alias YELLOW = 0xDBAB79
alias BLUE = 0x71BEF2
alias MAGENTA = 0xD290E4
alias CYAN = 0x66C2CD
alias GRAY = 0xB9BFCA


# Convenience functions for quick style application
fn render_as_color[T: SizedWritable, //](text: T, color: UInt32, profile: Int = -1) -> String:
    """Render the text with the given color.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        color: The color to apply.
        profile: The profile to use.

    Returns:
        The text with the color applied.
    """
    if profile == -1:
        return Style().foreground(color).render(text)
    return Style(profile).foreground(color).render(text)


fn red[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply red color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the red color applied.
    """
    return render_as_color(text, RED, profile)


fn green[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply green color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the green color applied.
    """
    return render_as_color(text, GREEN, profile)


fn yellow[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply yellow color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the yellow color applied.
    """
    return render_as_color(text, YELLOW, profile)


fn blue[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply blue color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the blue color applied.
    """
    return render_as_color(text, BLUE, profile)


fn magenta[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply magenta color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the magenta color applied.
    """
    return render_as_color(text, MAGENTA, profile)


fn cyan[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply cyan color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the cyan color applied.
    """
    return render_as_color(text, CYAN, profile)


fn gray[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply gray color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the gray color applied.
    """
    return render_as_color(text, GRAY, profile)


fn render_with_background_color[T: SizedWritable, //](text: T, color: UInt32, profile: Int = -1) -> String:
    """Render the text with the given background color.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        color: The color to apply.
        profile: The profile to use.

    Returns:
        The text with the background color applied.
    """
    if profile == -1:
        return Style().background(color).render(text)
    return Style(profile).background(color).render(text)


fn red_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply red background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the red background color applied.
    """
    return render_with_background_color(text, RED, profile)


fn green_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply green background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the green background color applied.
    """
    return render_with_background_color(text, GREEN, profile)


fn yellow_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply yellow background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the yellow background color applied.
    """
    return render_with_background_color(text, YELLOW, profile)


fn blue_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply blue background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the blue background color applied.
    """
    return render_with_background_color(text, BLUE, profile)


fn magenta_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply magenta background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the magenta background color applied.
    """
    return render_with_background_color(text, MAGENTA, profile)


fn cyan_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply cyan background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the cyan background color applied.
    """
    return render_with_background_color(text, CYAN, profile)


fn gray_background[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Apply gray background color to the text.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The text with the gray background color applied.
    """
    return render_with_background_color(text, GRAY, profile)


fn bold[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Render the text with the bold style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The bolded text.
    """
    if profile == -1:
        return Style().bold().render(text)
    return Style(profile).bold().render(text)


fn faint[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Render the text with the faint style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The faint text.
    """
    if profile == -1:
        return Style().faint().render(text)
    return Style(profile).faint().render(text)


fn italic[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Render the text with the italic style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The italicized text.
    """
    if profile == -1:
        return Style().italic().render(text)
    return Style(profile).italic().render(text)


fn underline[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Render the text with the underline style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The underlined text.
    """
    if profile == -1:
        return Style().underline().render(text)
    return Style(profile).underline().render(text)


fn overline[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Render the text with the overline style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The overlined text.
    """
    if profile == -1:
        return Style().overline().render(text)
    return Style(profile).overline().render(text)


fn crossout[T: SizedWritable, //](text: T, profile: Int = -1) -> String:
    """Render the text with the crossout style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The crossed out text.
    """
    if profile == -1:
        return Style().crossout().render(text)
    return Style(profile).crossout().render(text)
