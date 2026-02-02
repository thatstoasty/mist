import mist.transform.ansi
from mist.transform.unicode import char_width


@fieldwise_init
struct TruncateWriter(Movable, Stringable):
    """A truncating writer that truncates content at the given printable cell width.

    #### Examples:
    ```mojo
    from mist.transform import TruncateWriter

    fn main():
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
    var in_ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(out self, width: UInt, tail: String, *, in_ansi: Bool = False):
        """Initializes a new truncate-writer instance.

        Args:
            width: The maximum printable cell width.
            tail: The tail to append to the truncated content.
            in_ansi: Whether the current character is part of an ANSI escape sequence.
        """
        self.width = width
        self.tail = tail
        self.in_ansi = in_ansi
        self.ansi_writer = ansi.Writer()

    fn __str__(self) -> String:
        """Returns the truncated result as a string by copying the content of the internal buffer.

        Returns:
            The truncated string.
        """
        return String(self.ansi_writer.forward)

    fn as_string_slice(self) -> StringSlice[origin_of(self.ansi_writer.forward)]:
        """Returns the truncated result as a string slice by referencing the content of the internal buffer.

        Returns:
            The truncated string slice.
        """
        return StringSlice(self.ansi_writer.forward)

    fn write(mut self, text: StringSlice) -> None:
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

        for codepoint in text.codepoints():
            if codepoint.to_u32() == ansi.ANSI_MARKER_BYTE:
                # ANSI escape sequence
                self.in_ansi = True
            elif self.in_ansi:
                if ansi.is_terminator(codepoint):
                    # ANSI sequence terminated
                    self.in_ansi = False
            else:
                cur_width += char_width(codepoint)

            if cur_width > self.width:
                self.ansi_writer.forward.write(self.tail)
                if self.ansi_writer.last_sequence() != StaticString(""):
                    self.ansi_writer.reset_ansi()
                return

            self.ansi_writer.write(codepoint)


fn truncate(text: StringSlice, width: UInt, tail: String = "") -> String:
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

    fn main():
        print(truncate("Hello, World!", 5, "."))
    ```
    """
    var writer = TruncateWriter(width, tail)
    writer.write(text)
    return String(writer)
