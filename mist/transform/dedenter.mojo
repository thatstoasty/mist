"""Removes common leading indentation from multi-line text."""
from mist.transform import ansi
from mist.transform.ansi import NEWLINE_BYTE, SPACE_BYTE, TAB_BYTE, _is_plain_ascii


def _calculate_minimum_indentation[origin: ImmOrigin, //](text: StringSpan[origin]) -> UInt:
    """Detects the indentation level shared by all lines.

    ANSI escape sequences are transparent to this scan: they neither count as
    indentation nor end it, so a sequence ahead of a line's leading whitespace
    (e.g. a color applied to an indented line) does not defeat detection.

    Args:
        text: The text to dedent.

    Returns:
        The minimum indentation level.
    """
    var cur_indent: UInt = 0
    var min_indent: UInt = 0
    var should_append = True
    var scanner = ansi.SequenceScanner()

    if _is_plain_ascii(text):
        # Plain ASCII has no sequences to step over and no multi-byte
        # codepoints, so the scan reduces to a walk over the raw bytes.
        var bytes = text.as_bytes()
        var ptr = bytes.unsafe_ptr()
        for index in range(len(bytes)):
            var byte = ptr[unsafe_offset=index]
            if byte == UInt8(TAB_BYTE) or byte == UInt8(SPACE_BYTE):
                if should_append:
                    cur_indent += 1
            elif byte == UInt8(NEWLINE_BYTE):
                cur_indent = 0
                should_append = True
            else:
                if should_append and (min_indent == 0 or cur_indent < min_indent):
                    min_indent = cur_indent
                    cur_indent = 0
                should_append = False

        return min_indent

    for codepoint in text.codepoints():
        if scanner.step(codepoint):
            continue

        var rune = codepoint.to_u32()
        if rune == TAB_BYTE or rune == SPACE_BYTE:
            if should_append:
                cur_indent += 1
        elif rune == NEWLINE_BYTE:
            cur_indent = 0
            should_append = True
        else:
            if should_append and (min_indent == 0 or cur_indent < min_indent):
                min_indent = cur_indent
                cur_indent = 0
            should_append = False

    return min_indent


def _apply_dedent[origin: ImmOrigin, //](text: StringSpan[origin], indent: UInt) -> String:
    """Returns a copy `text` that's been dedented
    by removing the shared indentation level.

    ANSI escape sequences are always copied through in place and never count
    against the columns being stripped.

    Args:
        text: The text to dedent.
        indent: The number of spaces to remove from the beginning of each line.

    Returns:
        A new dedented string.
    """
    var should_omit = True
    var omitted: UInt = 0
    var buf = String(capacity=Int(Float64(text.byte_length()) * 1.25))
    var scanner = ansi.SequenceScanner()

    if _is_plain_ascii(text):
        # Plain ASCII is copied in runs between the stripped columns rather than
        # a codepoint at a time.
        var bytes = text.as_bytes()
        var length = len(bytes)
        var ptr = bytes.unsafe_ptr()
        var index = 0
        var run_start = 0

        while index < length:
            var byte = ptr[unsafe_offset=index]
            if byte == UInt8(TAB_BYTE) or byte == UInt8(SPACE_BYTE):
                if should_omit:
                    if omitted < indent:
                        omitted += 1
                        # This column is dropped, so the pending run stops short
                        # of it and resumes after it.
                        buf.write(text[byte=run_start:index])
                        index += 1
                        run_start = index
                        continue
                    should_omit = False
            elif byte == UInt8(NEWLINE_BYTE):
                omitted = 0
                should_omit = True

            index += 1

        buf.write(text[byte=run_start:length])
        return buf^

    for codepoint in text.codepoints():
        if scanner.step(codepoint):
            buf.write(codepoint)
            continue

        var rune = codepoint.to_u32()
        if rune == TAB_BYTE or rune == SPACE_BYTE:
            if should_omit:
                if omitted < indent:
                    omitted += 1
                    continue
                should_omit = False
            buf.write(codepoint)
        elif rune == NEWLINE_BYTE:
            omitted = 0
            should_omit = True
            buf.write(codepoint)
        else:
            buf.write(codepoint)

    return buf^


def dedent[origin: ImmOrigin, //](text: StringSpan[origin]) -> String:
    """Automatically detects the maximum indentation shared by all lines and
    trims them accordingly.

    Args:
        text: The text to dedent.

    Returns:
        A copy of the original text that's been dedented.

    #### Examples:
    ```mojo
    from mist import dedent

    def main() -> None:
        var text = dedent("    Hello, World!\\n    This is a test.\\n    \\n")
        print(text)
    ```
    """
    var indent = _calculate_minimum_indentation(text)
    if indent == 0:
        return String(text)

    return _apply_dedent(text, indent)
