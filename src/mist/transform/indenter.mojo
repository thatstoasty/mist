import utils.write
from mist.transform.bytes import ByteWriter
import mist.transform.ansi
from mist.transform.ansi import SPACE, NEWLINE_BYTE


@fieldwise_init
struct Writer(Movable, Stringable, Writable):
    """A writer that indents content by a given number of spaces.

    #### Examples:
    ```mojo
    from mist.transform import indenter as indent

    fn main():
        var writer = indent.Writer(4)
        writer.write("Hello, World!")
        print(writer)
    ```
    """

    var indent: Int
    """The number of spaces to indent each line."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores the text content."""
    var skip_indent: Bool
    """Whether to skip the indentation for the next line."""
    var in_ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""

    fn __init__(out self, indent: Int):
        """Initializes a new indent-writer instance.

        Args:
            indent: The number of spaces to indent each line.
        """
        self.indent = indent
        self.ansi_writer = ansi.Writer()
        self.skip_indent = False
        self.in_ansi = False

    fn __str__(self) -> String:
        """Returns the indented result as a string by copying the content of the internal buffer.

        Returns:
            The indented string.
        """
        return String(self.ansi_writer.forward)

    fn write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content of the buffer to the specified writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write the content to.
        """
        writer.write(self.ansi_writer.forward)

    fn consume(mut self) -> String:
        """Returns the indented result as a string by taking the data from the internal buffer.

        Returns:
            The indented string.
        """
        return self.ansi_writer.forward.consume()

    fn write(mut self, text: StringSlice) -> None:
        """Writes the text, `text`, to the writer,
        indenting each line by `self.indent` spaces.

        Args:
            text: The content to write.
        """
        for codepoint in text.codepoints():
            # ANSI escape sequence
            if codepoint.to_u32() == ansi.ANSI_MARKER_BYTE:
                self.in_ansi = True
            elif self.in_ansi:
                # ANSI sequence terminated
                if ansi.is_terminator(codepoint):
                    self.in_ansi = False
            else:
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    self.ansi_writer.write(SPACE * self.indent)
                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                # end of current line
                if codepoint.to_u32() == NEWLINE_BYTE:
                    self.skip_indent = False

            self.ansi_writer.write(codepoint)


fn indent(text: StringSlice, indent: Int) -> String:
    """Indents `text` with a `indent` number of spaces.

    Args:
        text: The string to indent.
        indent: The number of spaces to indent.

    Returns:
        A new indented string.

    #### Examples:
    ```mojo
    from mist import indent

    fn main():
        print(indent("Hello, World!", 4))
    ```
    """
    var writer = Writer(indent)
    writer.write(text)
    return writer.consume()
