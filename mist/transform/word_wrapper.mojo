"""A writer that wraps written content on word boundaries."""
from mist.transform import ansi
from mist.transform.ansi import CARRIAGE_RETURN_BYTE, NEWLINE_BYTE, SPACE, SPACE_BYTE, _is_plain_ascii
from mist.transform.unicode import grapheme_width


comptime DEFAULT_NEWLINE = "\n"
"""The default newline character."""
comptime DEFAULT_BREAKPOINT = "-"
"""The default breakpoint character."""


@fieldwise_init
@explicit_destroy("Call finish() to retrieve the final result and destroy the writer.")
struct WordWrapWriter[keep_newlines: Bool = True](Deinitable where False, Movable):
    """A word-wrapping writer that wraps content based on words at the given limit.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    #### Examples:
    ```mojo
    from mist.transform import WordWrapWriter

    def main():
        var writer = WordWrapWriter(5)
        writer.write("Hello, World!")
        print(writer^.finish())
    ```
    """

    var limit: UInt
    """The maximum number of characters per line."""
    var breakpoint: Codepoint
    """The character to use as a breakpoint."""
    var newline: String
    """The string written when this writer inserts a line break."""
    var buf: String
    """The buffer that stores the word-wrapped content."""
    var space: String
    """The buffer that stores the space between words."""
    var word: String
    """The buffer that stores the current word."""
    var word_width: UInt
    """The printable cell width of `word`, tracked as it is appended to."""
    var space_width: UInt
    """The printable cell width of `space`, tracked as it is appended to."""
    var line_len: UInt
    """The current line length."""
    var scanner: ansi.SequenceScanner
    """Tracks whether the current character is part of an ANSI escape sequence."""

    def __init__(
        out self,
        limit: UInt,
        *,
        breakpoint: String = DEFAULT_BREAKPOINT,
        newline: String = DEFAULT_NEWLINE,
        line_len: UInt = 0,
    ):
        """Initializes a new word wrap writer.

        Args:
            limit: The maximum number of characters per line.
            breakpoint: The character to use as a breakpoint.
            newline: The string written when this writer inserts a line break.
            line_len: The current line length.
        """
        self.limit = limit
        self.breakpoint = Codepoint(Byte(ord(breakpoint)))
        self.newline = newline
        self.buf = String()
        self.space = String()
        self.word = String()
        self.word_width = 0
        self.space_width = 0
        self.line_len = line_len
        self.scanner = ansi.SequenceScanner()

    def add_space(mut self):
        """Write the content of the space buffer to the word-wrap buffer."""
        self.line_len += self.space_width
        self.buf.write(self.space)
        self.clear_space()

    def clear_space(mut self):
        """Empty the space buffer and reset its tracked width."""
        self.space = String(capacity=self.space.capacity())
        self.space_width = 0

    def add_word(mut self):
        """Write the content of the word buffer to the word-wrap buffer."""
        if self.word.byte_length() > 0:
            self.add_space()
            self.line_len += self.word_width
            self.buf.write(self.word)
            self.word = String(capacity=self.word.capacity())
            self.word_width = 0

    def add_newline(mut self):
        """Write a newline to the word-wrap buffer and reset the line length & space buffer."""
        self.buf.write(self.newline)
        self.line_len = 0
        self.clear_space()

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `content`, to the writer, wrapping lines once the limit is reached.
        If the word cannot fit on the line, then it will be written to the next line.

        Args:
            text: The content to write.
        """
        if self.limit == 0:
            self.buf.write(text)
            return

        var content: String
        comptime if not Self.keep_newlines:
            content = String(text.strip()).replace("\r\n", " ").replace("\n", " ")
        else:
            content = String(text)

        # A non-ASCII breakpoint can never match an ASCII byte, so the byte-wise
        # path would have to compare against a truncated value; keep such a
        # writer on the general path.
        if self.breakpoint.to_u32() < 0x80 and not self.scanner.is_active() and _is_plain_ascii(content):
            return self._write_ascii(content)

        return self._write_general(content)

    def _write_general[origin: ImmOrigin, //](mut self, content: StringSpan[origin]) -> None:
        """Word-wraps by segmenting grapheme clusters. Correct for any input.

        Assumes newline stripping has already been applied.

        Parameters:
            origin: The origin of the string.

        Args:
            content: The prepared content to wrap.
        """
        # Compare whole clusters rather than pulling codepoints out of the
        # inner loop: hoisting the inner loop variable into the enclosing
        # scope currently hangs the compiler.
        var breakpoint = String(self.breakpoint)

        for grapheme in content.graphemes():
            var printable = True
            for codepoint in grapheme.codepoints():
                if self.scanner.step(codepoint):
                    printable = False

            # ANSI escape sequence
            if not printable:
                self.word.write(grapheme)
                continue

            # end of current line
            # see if we can add the content of the space buffer to the current line
            if ansi.is_newline(grapheme):
                if self.word.byte_length() == 0:
                    if self.line_len + self.space_width > self.limit:
                        self.line_len = 0

                    # preserve whitespace
                    else:
                        self.buf.write(self.space)
                    self.clear_space()
                self.add_word()

                # Write the break exactly as it appeared in the input, so a
                # CRLF survives intact. `add_newline` is still used for the
                # breaks that wrapping itself inserts.
                self.buf.write(grapheme)
                self.line_len = 0
                self.clear_space()

            # end of current word
            elif grapheme == SPACE:
                self.add_word()
                self.space.write(SPACE)
                self.space_width += 1

            # valid breakpoint
            elif grapheme == breakpoint:
                self.add_space()
                self.add_word()
                self.buf.write(self.breakpoint)

            # any other character
            else:
                self.word.write(grapheme)

                # Accumulate the width instead of re-measuring the whole word
                # buffer on every character, which made this loop quadratic in
                # the length of a word.
                self.word_width += grapheme_width(grapheme)

                # add a line break if the current word would exceed the line's
                # character limit
                if self.word_width < self.limit and self.line_len + self.space_width + self.word_width > self.limit:
                    self.add_newline()

    def _write_ascii[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Word-wraps a span already known to be plain ASCII with no escape sequences.

        Equivalent to the grapheme path, but reads the span a byte at a time and
        appends each run of word characters to the word buffer in one copy
        rather than one per cluster. In ASCII every byte is its own grapheme
        cluster except `CRLF`, which is paired explicitly so a break is never
        split across two iterations.

        Parameters:
            origin: The origin of the string.

        Args:
            text: The content to wrap, which must be plain ASCII.
        """
        var bytes = text.as_bytes()
        var length = len(bytes)
        var ptr = bytes.unsafe_ptr()
        var breakpoint_byte = UInt8(self.breakpoint.to_u32())
        var index = 0

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

            # end of current line
            # see if we can add the content of the space buffer to the current line
            if break_length != 0:
                if self.word.byte_length() == 0:
                    if self.line_len + self.space_width > self.limit:
                        self.line_len = 0

                    # preserve whitespace
                    else:
                        self.buf.write(self.space)
                    self.clear_space()
                self.add_word()

                # Write the break exactly as it appeared in the input, so a
                # CRLF survives intact. `add_newline` is still used for the
                # breaks that wrapping itself inserts.
                self.buf.write(text[byte = index : index + break_length])
                self.line_len = 0
                self.clear_space()
                index += break_length
                continue

            # end of current word
            if byte == UInt8(SPACE_BYTE):
                self.add_word()
                self.space.write(SPACE)
                self.space_width += 1
                index += 1
                continue

            # valid breakpoint
            if byte == breakpoint_byte:
                self.add_space()
                self.add_word()
                self.buf.write(self.breakpoint)
                index += 1
                continue

            # A run of ordinary characters all lands in the word buffer, so the
            # bytes are copied once at the end rather than one at a time. Only
            # the width bookkeeping has to advance per byte, because a line
            # break may need to be inserted partway through the run -- and that
            # writes to `buf`, never to `word`, so deferring the copy cannot
            # reorder the output.
            var run_start = index
            while index < length:
                var run_byte = ptr[unsafe_offset=index]
                if run_byte == UInt8(NEWLINE_BYTE) or run_byte == UInt8(SPACE_BYTE) or run_byte == breakpoint_byte:
                    break
                if (
                    run_byte == UInt8(CARRIAGE_RETURN_BYTE)
                    and index + 1 < length
                    and ptr[unsafe_offset=index + 1] == UInt8(NEWLINE_BYTE)
                ):
                    break

                # Accumulate the width instead of re-measuring the whole word
                # buffer on every character, which made this loop quadratic in
                # the length of a word.
                if run_byte >= 0x20 and run_byte <= 0x7E:
                    self.word_width += 1

                # add a line break if the current word would exceed the line's
                # character limit
                if self.word_width < self.limit and self.line_len + self.space_width + self.word_width > self.limit:
                    self.add_newline()

                index += 1

            self.word.write(text[byte=run_start:index])

    def finish(deinit self) -> String:
        """Finishes the word-wrap operation. Always call it before trying to retrieve the final result.

        Returns:
            The final word-wrapped string.
        """
        self.add_word()
        return self.buf^


def word_wrap[
    origin: ImmOrigin, //, keep_newlines: Bool = True
](
    text: StringSpan[origin],
    limit: UInt,
    *,
    newline: String = DEFAULT_NEWLINE,
    breakpoint: String = DEFAULT_BREAKPOINT,
) -> String:
    """Wraps `text` at `limit` characters per line, if the word can fit on the line.
    Otherwise, it will break prior to adding the word, then add it to the next line.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    Args:
        text: The string to wrap.
        limit: The maximum number of characters per line.
        newline: The string written when wrapping inserts a line break.
        breakpoint: The character to use as a breakpoint.

    Returns:
        A new word wrapped string.

    #### Examples:
    ```mojo
    from mist import word_wrap

    def main():
        print(word_wrap("Hello, World!", 5))
    ```
    """
    if limit == 0:
        return String(text)

    var writer = WordWrapWriter[keep_newlines](limit, newline=newline, breakpoint=breakpoint)
    writer.write(text)
    return writer^.finish()
