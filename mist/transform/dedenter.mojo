fn _calculate_minimum_indentation(text: StringSlice) -> UInt:
    """Detects the indentation level shared by all lines.

    Args:
        text: The text to dedent.

    Returns:
        The minimum indentation level.
    """
    var cur_indent: UInt = 0
    var min_indent: UInt = 0
    var should_append = True

    for codepoint in text.codepoint_slices():
        if codepoint == "\t" or codepoint == " ":
            if should_append:
                cur_indent += 1
        elif codepoint == "\n":
            cur_indent = 0
            should_append = True
        else:
            if should_append and (min_indent == 0 or cur_indent < min_indent):
                min_indent = cur_indent
                cur_indent = 0
            should_append = False

    return min_indent


fn _apply_dedent(text: StringSlice, indent: UInt) -> String:
    """Returns a copy `text` that's been dedented
    by removing the shared indentation level.

    Args:
        text: The text to dedent.
        indent: The number of spaces to remove from the beginning of each line.

    Returns:
        A new dedented string.
    """
    var should_omit = True
    var omitted: UInt = 0
    var buf = String(capacity=Int(text.byte_length() * 1.25))

    for codepoint in text.codepoint_slices():
        if codepoint == "\t" or codepoint == " ":
            if should_omit:
                if omitted < indent:
                    omitted += 1
                    continue
                should_omit = False
            buf.write(codepoint)
        elif codepoint == "\n":
            omitted = 0
            should_omit = True
            buf.write(codepoint)
        else:
            buf.write(codepoint)

    return buf^


fn dedent(text: StringSlice) -> String:
    """Automatically detects the maximum indentation shared by all lines and
    trims them accordingly.

    Args:
        text: The text to dedent.

    Returns:
        A copy of the original text that's been dedented.

    #### Examples:
    ```mojo
    from mist import dedent

    fn main() -> None:
        var text = dedent("    Hello, World!\\n    This is a test.\\n    \\n")
        print(text)
    ```
    """
    var indent = _calculate_minimum_indentation(text)
    if indent == 0:
        return String(text)

    return _apply_dedent(text, indent)
