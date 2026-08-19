"""A writer that truncates written content at a given printable cell width."""
from mist.transform import ansi
from mist.transform.unicode import grapheme_width


@fieldwise_init
struct TruncateWriter(Movable, Writable):
    """A truncating writer that truncates content at the given printable cell width.

    #### Examples:
    ```mojo
    from mist.transform import TruncateWriter

    def main():
        var writer = TruncateWriter(4, tail=".")
        writer.write("Hello, World!")
        print(String(writer))
    ```
    """

    var width: UInt
    """The maximum printable cell width."""
    var tail: String
    """The tail to append to the truncated content."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores the text content."""
    var scanner: ansi.SequenceScanner
    """Tracks whether the current character is part of an ANSI escape sequence."""

    def __init__(out self, width: UInt, var tail: String):
        """Initializes a new truncate-writer instance.

        Args:
            width: The maximum printable cell width.
            tail: The tail to append to the truncated content.
        """
        self.width = width
        self.tail = tail^
        self.scanner = ansi.SequenceScanner()
        self.ansi_writer = ansi.Writer()

    def write_to(self, mut writer: Some[Writer]):
        """Writes the truncated result to the given writer.

        Args:
            writer: The writer to write the truncated result to.
        """
        writer.write(self.ansi_writer.forward)

    def as_string_slice(self) -> StringSpan[origin_of(self.ansi_writer.forward)]:
        """Returns the truncated result as a string slice by referencing the content of the internal buffer.

        Returns:
            The truncated string slice.
        """
        return StringSpan(self.ansi_writer.forward)

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `content`, to the writer, truncating content at the given printable cell width,
        leaving any ANSI sequences intact.

        Args:
            text: The content to write.
        """
        var tw = ansi.printable_rune_width(self.tail)
        if self.width < tw:
            self.ansi_writer.forward.write(self.tail)
            return

        self.width -= tw
        var cur_width: UInt = 0

        for grapheme in text.graphemes():
            # A cluster is either wholly escape sequence or wholly content, but
            # the scanner is stepped over every codepoint so that non-ASCII
            # inside a string sequence is skipped rather than measured.
            var printable = True
            for codepoint in grapheme.codepoints():
                if self.scanner.step(codepoint):
                    printable = False

            if printable:
                cur_width += grapheme_width(grapheme)

                if cur_width > self.width:
                    self.ansi_writer.forward.write(self.tail)
                    if self.ansi_writer.last_sequence() != StaticString(""):
                        self.ansi_writer.reset_ansi()
                    return

            # Clusters are written whole. Writing a prefix would emit a partial
            # cluster -- a dangling ZWJ, or an emoji stripped of its skin tone
            # modifier -- which renders differently than the text it came from.
            self.ansi_writer.write(grapheme)


def truncate[origin: ImmOrigin, //](text: StringSpan[origin], width: UInt, var tail: String = "") -> String:
    """Truncates `text` at `width` characters. A tail is then added to the end of the string.

    Args:
        text: The string to truncate.
        width: The maximum printable cell width.
        tail: The tail to append to the truncated content.

    Returns:
        A new truncated string.

    #### Examples:
    ```mojo
    from mist import truncate

    def main():
        print(truncate("Hello, World!", 5, "."))
    ```
    """
    var writer = TruncateWriter(width, tail^)
    writer.write(text)
    return String(writer)
