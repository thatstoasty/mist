"""A writer that indents written content by a fixed number of spaces."""
from mist.transform import ansi
from mist.transform.ansi import LF_CODEPOINT, SPACE, _is_plain_ascii


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

    def __init__(out self, indent: UInt):
        """Initializes a new indent-writer instance.

        Args:
            indent: The number of spaces to indent each line.
        """
        self.indent = indent
        self.ansi_writer = ansi.Writer()
        self.skip_indent = False

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
        if not self.ansi_writer.is_scanning() and _is_plain_ascii(text):
            return self._write_ascii(text)

        return self._write_general(text)

    def _write_general[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Indents by walking codepoints. Correct for any input.

        Parameters:
            origin: The origin of the string.

        Args:
            text: The content to write.
        """
        for codepoint in text.codepoints():
            # Classify through the writer's own scanner and hand the answer back
            # to it, rather than keeping a second scanner in lockstep and
            # stepping every codepoint twice.
            var is_sequence = self.ansi_writer.step(codepoint)
            if not is_sequence:
                if not self.skip_indent:
                    self.ansi_writer.reset_ansi()
                    self.ansi_writer.write(SPACE * Int(self.indent))
                    self.skip_indent = True
                    self.ansi_writer.restore_ansi()

                # end of current line
                if codepoint == LF_CODEPOINT:
                    self.skip_indent = False

            self.ansi_writer.write_stepped(codepoint, is_sequence=is_sequence)

    def _write_ascii[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Indents a span already known to be plain ASCII with no escape sequences.

        Equivalent to the codepoint path, but emits each line's content in one
        copy instead of one per codepoint, and builds the run of indent spaces
        once for the whole span rather than once per line.

        Parameters:
            origin: The origin of the string.

        Args:
            text: The content to write, which must be plain ASCII.
        """
        var bytes = text.as_bytes()
        var length = len(bytes)
        var ptr = bytes.unsafe_ptr()
        var indentation = SPACE * Int(self.indent)
        var index = 0
        var run_start = 0

        while index < length:
            if not self.skip_indent:
                # The indent precedes the line it belongs to, so the content
                # buffered since the last break has to be flushed ahead of it.
                self.ansi_writer.forward.write(text[byte=run_start:index])
                run_start = index

                self.ansi_writer.reset_ansi()
                self.ansi_writer.write(indentation)
                self.skip_indent = True
                self.ansi_writer.restore_ansi()

            # end of current line
            if ptr[unsafe_offset=index] == UInt8(LF_CODEPOINT):
                self.skip_indent = False

            index += 1

        self.ansi_writer.forward.write(text[byte=run_start:length])


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
