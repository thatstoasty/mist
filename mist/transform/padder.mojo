from io import write

import mist.transform.ansi
from mist.transform.ansi import NEWLINE_BYTE, SPACE
from mist.transform.bytes import ByteWriter
from mist.transform.unicode import char_width


@fieldwise_init
struct Writer(Movable, Stringable, Writable):
    """A padding writer that pads content to the given printable cell width.

    #### Examples:
    ```mojo
    from mist.transform import padder as padding

    fn main():
        var writer = padding.Writer(4)
        writer.write("Hello, World!")
        writer.flush()
        print(String(writer))
    ```
    """

    var padding: UInt
    """Padding width to apply to each line."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores intermediary text content."""
    var cache: ByteWriter
    """The buffer that stores the padded content after it's been flushed."""
    var line_len: UInt
    """The current line length."""
    var in_ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(
        out self,
        padding: UInt,
        *,
        line_len: UInt = 0,
        in_ansi: Bool = False,
    ):
        """Initializes a new padding-writer instance.

        Args:
            padding: The padding width.
            line_len: The current line length.
            in_ansi: Whether the current character is part of an ANSI escape sequence.
        """
        self.padding = padding
        self.line_len = line_len
        self.in_ansi = in_ansi
        self.cache = ByteWriter()
        self.ansi_writer = ansi.Writer()

    fn __str__(self) -> String:
        """Returns the padded result as a string by copying the content of the internal buffer.

        Returns:
            The padded string.
        """
        return String(self.cache)

    fn as_string_slice(self) -> StringSlice[origin_of(self.cache._data)]:
        """Returns the padded result as a `StringSlice` by copying the content of the internal buffer.

        Returns:
            The padded `StringSlice`.
        """
        return self.cache.as_string_slice()

    fn write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content of the buffer to the specified writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write the content to.
        """
        writer.write(self.cache)

    fn write(mut self, text: StringSlice) -> None:
        """Writes the text, `content`, to the writer,
        padding the text with a `self.width` number of spaces.

        Args:
            text: The content to write.
        """
        for codepoint in text.codepoints():
            if codepoint.to_u32() == ansi.ANSI_MARKER_BYTE:
                self.in_ansi = True
            elif self.in_ansi:
                if ansi.is_terminator(codepoint):
                    self.in_ansi = False
            else:
                if codepoint.to_u32() == NEWLINE_BYTE:
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0
                else:
                    self.line_len += char_width(codepoint)

            self.ansi_writer.write(codepoint)

    fn pad(mut self):
        """Pads the current line with spaces to the given width."""
        if self.padding > 0 and self.line_len < self.padding:
            self.ansi_writer.write(SPACE * Int(self.padding - self.line_len))

    fn flush(mut self):
        """Finishes the padding operation. Always call it before trying to retrieve the final result."""
        if self.line_len != 0:
            self.pad()

        self.cache.clear()
        self.cache.write(self.ansi_writer.forward)
        self.line_len = 0
        self.in_ansi = False


fn padding(text: StringSlice, width: UInt) -> String:
    """Right pads `text` with a `width` number of spaces.

    Args:
        text: The string to pad.
        width: The padding width.

    Returns:
        A new padded string.

    #### Examples:
    ```mojo
    from mist import padding

    fn main():
        print(padding("Hello, World!", 5))
    ```
    """
    var writer = Writer(width)
    writer.write(text)
    writer.flush()
    return String(writer)
