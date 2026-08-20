"""A writer that wraps written content to a fixed printable cell width."""
from mist.transform import ansi
from mist.transform.ansi import CARRIAGE_RETURN_BYTE, NEWLINE_BYTE, SPACE, SPACE_BYTE, _is_plain_ascii
from mist.transform.unicode import grapheme_width


comptime DEFAULT_NEWLINE = "\n"
"""The default newline character."""
comptime DEFAULT_TAB_WIDTH = 4
"""The default tab width."""


@fieldwise_init
struct WrapWriter[keep_newlines: Bool = True](Movable, Writable):
    """A line wrapping writer that wraps content based on the given limit.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    #### Examples:
    ```mojo
    from mist.transform import WrapWriter

    def main():
        var writer = WrapWriter(5)
        writer.write("Hello, World!")
        print(String(writer))
    ```
    """

    var limit: UInt
    """The maximum number of characters per line."""
    var newline: String
    """The string written when this writer inserts a line break."""
    var preserve_space: Bool
    """Whether to preserve space characters."""
    var tab_width: UInt
    """The width of a tab character."""
    var buf: String
    """The buffer that stores the wrapped content."""
    var line_len: UInt
    """The current line length."""
    var scanner: ansi.SequenceScanner
    """Tracks whether the current character is part of an ANSI escape sequence."""
    var forceful_newline: Bool
    """Whether to force a newline at the end of the line."""

    def __init__(
        out self,
        limit: UInt,
        *,
        newline: String = DEFAULT_NEWLINE,
        preserve_space: Bool = False,
        tab_width: UInt = DEFAULT_TAB_WIDTH,
        line_len: UInt = 0,
        forceful_newline: Bool = False,
    ):
        """Initializes a new line wrap writer.

        Args:
            limit: The maximum number of characters per line.
            newline: The string written when this writer inserts a line break.
            preserve_space: Whether to preserve space characters.
            tab_width: The width of a tab character.
            line_len: The current line length.
            forceful_newline: Whether to force a newline at the end of the line.
        """
        self.limit = limit
        self.newline = newline
        self.preserve_space = preserve_space
        self.tab_width = tab_width
        self.buf = String()
        self.line_len = line_len
        self.scanner = ansi.SequenceScanner()
        self.forceful_newline = forceful_newline

    def write_to(self, mut writer: Some[Writer]):
        """Writes the wrapped result to the given writer.

        Args:
            writer: The writer to write the wrapped result to.
        """
        writer.write(self.buf)

    def add_newline(mut self) -> None:
        """Adds a newline to the buffer and resets the line length."""
        self.buf.write(self.newline)
        self.line_len = 0

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `content`, to the writer, wrapping lines once the limit is reached.

        Args:
            text: The text to write to the writer.
        """
        var content = String(text)
        var tab_space = SPACE * Int(self.tab_width)
        content = content.replace("\t", tab_space)

        comptime if not Self.keep_newlines:
            content = content.replace("\r\n", "").replace("\n", "")

        if self.limit == 0:
            self.line_len += ansi.printable_rune_width(content)
            self.buf.write(content)
            return

        # Only the width up to the remaining budget matters here: if the content
        # overruns the line it goes to the wrapping loop, which measures each
        # cluster itself, so measuring the whole span first would be discarded
        # work.
        if self.line_len <= self.limit:
            var width = ansi.printable_width_within(content, self.limit - self.line_len)
            if width:
                self.line_len += width.value()
                self.buf.write(content)
                return

        if not self.scanner.is_active() and _is_plain_ascii(content):
            return self._write_ascii(content)

        return self._write_general(content)

    def _write_general[origin: ImmOrigin, //](mut self, content: StringSpan[origin]) -> None:
        """Wraps by segmenting grapheme clusters. Correct for any input.

        Assumes tab expansion and newline stripping have already been applied.

        Parameters:
            origin: The origin of the string.

        Args:
            content: The prepared content to wrap.
        """
        for grapheme in content.graphemes():
            var printable = True
            for codepoint in grapheme.codepoints():
                if self.scanner.step(codepoint):
                    printable = False

            if printable:
                if ansi.is_newline(grapheme):
                    # Write the break exactly as it appeared in the input, so a
                    # CRLF survives intact. `newline` governs only the breaks
                    # that wrapping itself inserts.
                    self.buf.write(grapheme)
                    self.line_len = 0
                    self.forceful_newline = False
                    continue

                var width = grapheme_width(grapheme)

                # Break before the cluster rather than within it, so a wrapped
                # line never ends with a partial glyph.
                if self.line_len + width > self.limit:
                    self.add_newline()
                    self.forceful_newline = True

                if self.line_len == 0:
                    if self.forceful_newline and not self.preserve_space and grapheme == SPACE:
                        continue
                else:
                    self.forceful_newline = False

                self.line_len += width

            self.buf.write(grapheme)

    def _write_ascii[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Wraps a span already known to be plain ASCII with no escape sequences.

        Equivalent to the grapheme path, but reads the span a byte at a time and
        copies each run of content in one go rather than one cluster at a time.
        In ASCII every byte is its own grapheme cluster except `CRLF`, which is
        paired explicitly so a break is never split across two iterations.

        Parameters:
            origin: The origin of the string.

        Args:
            text: The content to wrap, which must be plain ASCII.
        """
        var bytes = text.as_bytes()
        var length = len(bytes)
        var ptr = bytes.unsafe_ptr()
        var index = 0
        var run_start = 0

        while index < length:
            var byte = ptr[unsafe_offset=index]
            var break_length = 0

            if byte == UInt8(NEWLINE_BYTE):
                break_length = 1
            elif (
                byte == UInt8(CARRIAGE_RETURN_BYTE)
                and index + 1 < length
                and ptr[unsafe_offset=index + 1] == UInt8(NEWLINE_BYTE)
            ):
                break_length = 2

            if break_length != 0:
                # Write the break exactly as it appeared in the input, so a
                # CRLF survives intact. `newline` governs only the breaks that
                # wrapping itself inserts.
                index += break_length
                self.buf.write(text[byte=run_start:index])
                run_start = index
                self.line_len = 0
                self.forceful_newline = False
                continue

            # Control characters and DEL occupy no cells; everything else in
            # ASCII occupies exactly one.
            var cell_width: UInt = 1 if byte >= 0x20 and byte <= 0x7E else 0

            # Break before the byte rather than after, so a wrapped line never
            # exceeds the limit.
            if self.line_len + cell_width > self.limit:
                self.buf.write(text[byte=run_start:index])
                run_start = index
                self.add_newline()
                self.forceful_newline = True

            if self.line_len == 0:
                if self.forceful_newline and not self.preserve_space and byte == UInt8(SPACE_BYTE):
                    # The space is dropped, so the pending run has to stop short
                    # of it and resume after it.
                    self.buf.write(text[byte=run_start:index])
                    index += 1
                    run_start = index
                    continue
            else:
                self.forceful_newline = False

            self.line_len += cell_width
            index += 1

        self.buf.write(text[byte=run_start:length])


def wrap[
    origin: ImmOrigin, //, keep_newlines: Bool = True
](
    text: StringSpan[origin],
    limit: UInt,
    *,
    newline: String = DEFAULT_NEWLINE,
    preserve_space: Bool = False,
    tab_width: UInt = DEFAULT_TAB_WIDTH,
) -> String:
    """Wraps `text` at `limit` characters per line.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    Args:
        text: The string to wrap.
        limit: The maximum line length before wrapping.
        newline: The string written when wrapping inserts a line break.
        preserve_space: Whether to preserve space characters.
        tab_width: The width of a tab character.

    Returns:
        A new wrapped string.

    #### Examples:
    ```mojo
    from mist import wrap

    def main():
        print(wrap("Hello, World!", 5))
    ```
    """
    if limit == 0:
        return String(text)

    var writer = WrapWriter[keep_newlines](limit, newline=newline, preserve_space=preserve_space, tab_width=tab_width)
    writer.write(text)
    return String(writer)
