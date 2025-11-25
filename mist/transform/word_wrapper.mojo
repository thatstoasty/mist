from io import write

import mist.transform.ansi
from mist.transform.ansi import NEWLINE, SPACE, SPACE_BYTE
from mist.transform.bytes import ByteWriter


comptime DEFAULT_NEWLINE = "\n"
comptime DEFAULT_BREAKPOINT = "-"


@fieldwise_init
struct Writer[keep_newlines: Bool = True](Movable, Stringable, Writable):
    """A word-wrapping writer that wraps content based on words at the given limit.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    #### Examples:
    ```mojo
    from mist.transform import word_wrapper as word_wrap

    fn main():
        var writer = word_wrap.Writer(5)
        writer.write("Hello, World!")
        _ = writer.close()
        print(String(writer))
    ```
    """

    var limit: Int
    """The maximum number of characters per line."""
    var breakpoint: Codepoint
    """The character to use as a breakpoint."""
    var newline: Codepoint
    """The character to use as a newline."""
    var buf: ByteWriter
    """The buffer that stores the word-wrapped content."""
    var space: ByteWriter
    """The buffer that stores the space between words."""
    var word: ByteWriter
    """The buffer that stores the current word."""
    var line_len: Int
    """The current line length."""
    var ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(
        out self,
        limit: Int,
        *,
        breakpoint: String = DEFAULT_BREAKPOINT,
        newline: String = DEFAULT_NEWLINE,
        line_len: Int = 0,
        ansi: Bool = False,
    ):
        """Initializes a new word wrap writer.

        Args:
            limit: The maximum number of characters per line.
            breakpoint: The character to use as a breakpoint.
            newline: The character to use as a newline.
            line_len: The current line length.
            ansi: Whether the current character is part of an ANSI escape sequence.
        """
        self.limit = limit
        self.breakpoint = Codepoint(ord(breakpoint))
        self.newline = Codepoint(ord(newline))
        self.buf = ByteWriter()
        self.space = ByteWriter()
        self.word = ByteWriter()
        self.line_len = line_len
        self.ansi = ansi

    fn __str__(self) -> String:
        """Returns the word wrapped result as a string by copying the content of the internal buffer.

        Returns:
            The word wrapped string.
        """
        return String(self.buf)

    fn write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content of the buffer to the specified writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write the content to.
        """
        writer.write(self.buf)

    fn add_space(mut self):
        """Write the content of the space buffer to the word-wrap buffer."""
        self.line_len += len(self.space)
        self.buf.write(self.space)
        self.space.clear()

    fn add_word(mut self):
        """Write the content of the word buffer to the word-wrap buffer."""
        if len(self.word) > 0:
            self.add_space()
            self.line_len += ansi.printable_rune_width(self.word.as_string_slice())
            self.buf.write(self.word)
            self.word.clear()

    fn add_newline(mut self):
        """Write a newline to the word-wrap buffer and reset the line length & space buffer."""
        self.buf.write(NEWLINE)
        self.line_len = 0
        self.space.clear()

    fn write(mut self, text: StringSlice) -> None:
        """Writes the text, `content`, to the writer, wrapping lines once the limit is reached.
        If the word cannot fit on the line, then it will be written to the next line.

        Args:
            text: The content to write.
        """
        if self.limit == 0:
            self.buf.write(text)
            return

        var content: String

        @parameter
        if not keep_newlines:
            content = String(text.strip()).replace("\n", " ")
        else:
            content = String(text)

        for codepoint in content.codepoints():
            # ANSI escape sequence
            if codepoint.to_u32() == ansi.ANSI_MARKER_BYTE:
                self.word.write(codepoint)
                self.ansi = True
            elif self.ansi:
                self.word.write(codepoint)

                # ANSI sequence terminated
                if ansi.is_terminator(codepoint):
                    self.ansi = False

            # end of current line
            # see if we can add the content of the space buffer to the current line
            elif codepoint == self.newline:
                if len(self.word) == 0:
                    if self.line_len + len(self.space) > self.limit:
                        self.line_len = 0

                    # preserve whitespace
                    else:
                        self.buf.write(self.space)
                    self.space.clear()
                self.add_word()
                self.add_newline()

            # end of current word
            elif codepoint.to_u32() == SPACE_BYTE:
                self.add_word()
                self.space.write(SPACE)

            # valid breakpoint
            elif codepoint == self.breakpoint:
                self.add_space()
                self.add_word()
                self.buf.write(self.breakpoint)

            # any other character
            else:
                self.word.write(codepoint)

                # add a line break if the current word would exceed the line's
                # character limit
                var word_width = ansi.printable_rune_width(self.word.as_string_slice())
                if word_width < self.limit and self.line_len + len(self.space) + word_width > self.limit:
                    self.add_newline()

    fn close(mut self):
        """Finishes the word-wrap operation. Always call it before trying to retrieve the final result."""
        self.add_word()


fn word_wrap[
    keep_newlines: Bool = True
](
    text: StringSlice,
    limit: Int,
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
        newline: The character to use as a newline.
        breakpoint: The character to use as a breakpoint.

    Returns:
        A new word wrapped string.

    #### Examples:
    ```mojo
    from mist import word_wrap

    fn main():
        print(word_wrap("Hello, World!", 5))
    ```
    """
    var writer = Writer[keep_newlines=keep_newlines](limit, newline=newline, breakpoint=breakpoint)
    writer.write(text)
    writer.close()
    return String(writer)
