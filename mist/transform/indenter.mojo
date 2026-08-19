"""A writer that indents written content by a fixed number of spaces."""
from mist.transform import ansi
from mist.transform.ansi import NEWLINE_BYTE, SPACE


@fieldwise_init
struct IndentWriter(Movable, Writable):
    """A writer that indents content by a given number of spaces.

    #### Examples:
    ```mojo
    from mist.transform import indenter as indent

    def main():
        var writer = indent.IndentWriter(4)
        writer.write("Hello, World!")
        print(writer)
    ```
    """

    var indent: UInt
    """The number of spaces to indent each line."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores the text content."""
    var skip_indent: Bool
    """Whether to skip the indentation for the next line."""
    var scanner: ansi.SequenceScanner
    """Tracks whether the current character is part of an ANSI escape sequence."""

    def __init__(out self, indent: UInt):
        """Initializes a new indent-writer instance.

        Args:
            indent: The number of spaces to indent each line.
        """
        self.indent = indent
        self.ansi_writer = ansi.Writer()
        self.skip_indent = False
        self.scanner = ansi.SequenceScanner()

    def as_string_slice(self) -> StringSpan[origin_of(self.ansi_writer.forward)]:
        """Returns the indented result as a string slice by referencing the content of the internal buffer.

        Returns:
            The indented string slice.
        """
        return StringSpan(self.ansi_writer.forward)

    def write_to(self, mut writer: Some[Writer]):
        """Writes the content of the buffer to the specified writer.

        Args:
            writer: The writer to write the content to.
        """
        writer.write(self.ansi_writer.forward)

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `text`, to the writer,
        indenting each line by `self.indent` spaces.

        Args:
            text: The content to write.
        """
        for codepoint in text.codepoints():
            if not self.scanner.step(codepoint):
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    self.ansi_writer.write(SPACE * Int(self.indent))
                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                # end of current line
                if codepoint.to_u32() == NEWLINE_BYTE:
                    self.skip_indent = False

            self.ansi_writer.write(codepoint)


def indent[origin: ImmOrigin, //](text: StringSpan[origin], indent: UInt) -> String:
    """Indents `text` with a `indent` number of spaces.

    Args:
        text: The string to indent.
        indent: The number of spaces to indent.

    Returns:
        A new indented string.

    #### Examples:
    ```mojo
    from mist import indent

    def main():
        print(indent("Hello, World!", 4))
    ```
    """
    if indent == 0:
        return String(text)

    var writer = IndentWriter(indent)
    writer.write(text)
    return String(writer)
