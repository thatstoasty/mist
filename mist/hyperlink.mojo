from .style import OSC, ST


fn hyperlink(link: String, name: String) -> String:
    """Creates a hyperlink using OSC8.

    Args:
        link: The URL to link to.
        name: The text to display.

    Returns:
        The hyperlink text.
    """
    return OSC + "8;;" + link + ST + name + OSC + "8;;" + ST
