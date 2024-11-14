from .style import OSC, ST


fn hyperlink(link: String, name: String) -> String:
    """Creates a hyperlink using OSC8.

    Args:
        link: The URL to link to.
        name: The text to display.

    Returns:
        The hyperlink text.
    """
    var output = String(capacity=14 + len(link) + len(name))
    output.write(OSC, "8;;", link, ST, name, OSC, "8;;", ST)
    return output
