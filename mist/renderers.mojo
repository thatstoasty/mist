from mist.profile import Profile
from mist.style import Style


comptime RED = 0xE88388
comptime GREEN = 0xA8CC8C
comptime YELLOW = 0xDBAB79
comptime BLUE = 0x71BEF2
comptime MAGENTA = 0xD290E4
comptime CYAN = 0x66C2CD
comptime GRAY = 0xB9BFCA


# Convenience functions for quick style application
fn render_as_color[T: Writable, //](text: T, color: UInt32, profile: Optional[Profile] = None) -> String:
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
    if not profile:
        return Style().foreground(color).render(text)
    return Style(profile.value()).foreground(color).render(text)


fn red[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn green[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn yellow[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn blue[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn magenta[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn cyan[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn gray[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn render_with_background_color[T: Writable, //](text: T, color: UInt32, profile: Optional[Profile] = None) -> String:
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
    if not profile:
        return Style().background(color).render(text)
    return Style(profile.value()).background(color).render(text)


fn red_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn green_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn yellow_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn blue_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn magenta_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn cyan_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn gray_background[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
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


fn bold[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
    """Render the text with the bold style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The bolded text.
    """
    if not profile:
        return Style().bold().render(text)
    return Style(profile.value()).bold().render(text)


fn faint[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
    """Render the text with the faint style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The faint text.
    """
    if not profile:
        return Style().faint().render(text)
    return Style(profile.value()).faint().render(text)


fn italic[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
    """Render the text with the italic style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The italicized text.
    """
    if not profile:
        return Style().italic().render(text)
    return Style(profile.value()).italic().render(text)


fn underline[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
    """Render the text with the underline style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The underlined text.
    """
    if not profile:
        return Style().underline().render(text)
    return Style(profile.value()).underline().render(text)


fn overline[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
    """Render the text with the overline style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The overlined text.
    """
    if not profile:
        return Style().overline().render(text)
    return Style(profile.value()).overline().render(text)


fn strikethrough[T: Writable, //](text: T, profile: Optional[Profile] = None) -> String:
    """Render the text with the strikethrough style applied.

    Parameters:
        T: The type of the text object.

    Args:
        text: The text to render.
        profile: The profile to use.

    Returns:
        The crossed out text.
    """
    if not profile:
        return Style().strikethrough().render(text)
    return Style(profile.value()).strikethrough().render(text)
