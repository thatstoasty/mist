"""A writer that wraps written content on word boundaries."""
from mist.transform import ansi
from mist.transform.ansi import SPACE
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
