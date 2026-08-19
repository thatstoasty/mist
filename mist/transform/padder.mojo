"""A writer that pads written content to a given printable cell width."""
from mist.transform import ansi
from mist.transform.ansi import SPACE
from mist.transform.unicode import grapheme_width


@explicit_destroy("Call finish() to retrieve the final result and destroy the writer.")
struct PaddingWriter(Deinitable where False, Movable):
    """A padding writer that pads content to the given printable cell width.

    #### Examples:
    ```mojo
    from mist.transform import PaddingWriter

    def main():
        var writer = PaddingWriter(4)
        writer.write("Hello, World!")
        print(writer^.finish())
    ```
    """

    var padding: UInt
    """Padding width to apply to each line."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores intermediary text content."""
    var cache: String
    """The buffer that stores the padded content after it's been flushed."""
    var line_len: UInt
    """The current line length."""
    var scanner: ansi.SequenceScanner
    """Tracks whether the current character is part of an ANSI escape sequence."""

    def __init__(
        out self,
        padding: UInt,
        *,
        line_len: UInt = 0,
    ):
        """Initializes a new padding-writer instance.

        Args:
            padding: The padding width.
            line_len: The current line length.
        """
        self.padding = padding
        self.line_len = line_len
        self.scanner = ansi.SequenceScanner()
        self.cache = String()
        self.ansi_writer = ansi.Writer()

    def as_string_slice(self) -> StringSpan[origin_of(self.cache)]:
        """Returns the padded result as a `StringSpan`.

        Returns:
            The padded `StringSpan`.
        """
        return self.cache

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `content`, to the writer,
        padding the text with a `self.width` number of spaces.

        Args:
            text: The content to write.
        """
        for grapheme in text.graphemes():
            var printable = True
            for codepoint in grapheme.codepoints():
                if self.scanner.step(codepoint):
                    printable = False

            if printable:
                if ansi.is_newline(grapheme):
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0
                else:
                    self.line_len += grapheme_width(grapheme)

            self.ansi_writer.write(grapheme)

    def pad(mut self):
        """Pads the current line with spaces to the given width."""
        if self.padding > 0 and self.line_len < self.padding:
            self.ansi_writer.write(SPACE * Int(self.padding - self.line_len))

    def finish(deinit self) -> String:
        """Finishes the padding operation. Always call it before trying to retrieve the final result.

        Returns:
            The final padded string.
        """
        if self.line_len != 0:
            self.pad()

        self.cache.write(self.ansi_writer.forward)
        return self.cache^


def padding[origin: ImmOrigin, //](text: StringSpan[origin], width: UInt) -> String:
    """Right pads `text` with a `width` number of spaces.

    Args:
        text: The string to pad.
        width: The padding width.

    Returns:
        A new padded string.

    #### Examples:
    ```mojo
    from mist import padding

    def main():
        print(padding("Hello, World!", 5))
    ```
    """
    if width == 0:
        return String(text)

    var writer = PaddingWriter(width)
    writer.write(text)
    return writer^.finish()
