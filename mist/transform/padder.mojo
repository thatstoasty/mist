"""A writer that pads written content to a given printable cell width."""
from mist.transform import ansi
from mist.transform.ansi import CARRIAGE_RETURN_BYTE, NEWLINE_BYTE, SPACE, _is_plain_ascii
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
    var line_len: UInt
    """The current line length."""

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
        self.ansi_writer = ansi.Writer()

    def as_string_slice(self) -> StringSpan[origin_of(self.ansi_writer.forward)]:
        """Returns the padded result so far as a `StringSpan`.

        Note that the final line is padded by `finish`, so before that call the
        slice reflects only the lines already terminated by a break.

        Returns:
            The padded `StringSpan`.
        """
        return StringSpan(self.ansi_writer.forward)

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `content`, to the writer,
        padding the text with a `self.width` number of spaces.

        Args:
            text: The content to write.
        """
        if not self.ansi_writer.is_scanning() and _is_plain_ascii(text):
            return self._write_ascii(text)

        return self._write_general(text)

    def _write_general[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Pads by segmenting grapheme clusters. Correct for any input.

        Parameters:
            origin: The origin of the string.

        Args:
            text: The content to write.
        """
        for grapheme in text.graphemes():
            # Sequence codepoints always form a prefix of a cluster: `ESC` is a
            # Control character, so it can only ever be a cluster's first
            # codepoint, which means the scanner can leave a sequence partway
            # through a cluster but never enter one. The whole cluster's
            # classification is therefore just the length of that prefix.
            var sequence_prefix = 0
            for codepoint in grapheme.codepoints():
                if not self.ansi_writer.step(codepoint):
                    break
                sequence_prefix += 1

            var printable = sequence_prefix == 0
            if printable:
                if ansi.is_newline(grapheme):
                    # end of current line, if pad right then add padding before newline
                    self.pad()
                    self.ansi_writer.reset_ansi()
                    self.line_len = 0
                else:
                    self.line_len += grapheme_width(grapheme)

            self._write_classified(grapheme, sequence_prefix)

    def _write_ascii[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Pads a span already known to be plain ASCII with no escape sequences.

        Equivalent to the grapheme path, but reads the span a byte at a time and
        emits each line in one copy rather than one per cluster. In ASCII every
        byte is its own grapheme cluster, with the sole exception of `CRLF`,
        which this pairs explicitly so a line break is never split across two
        iterations.

        Parameters:
            origin: The origin of the string.

        Args:
            text: The content to write, which must be plain ASCII.
        """
        var bytes = text.as_bytes()
        var length = len(bytes)
        var ptr = bytes.unsafe_ptr()
        var index = 0
        var line_start = 0

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

            if break_length == 0:
                # Control characters and DEL occupy no cells; everything else
                # in ASCII occupies exactly one.
                if byte >= 0x20 and byte <= 0x7E:
                    self.line_len += 1
                index += 1
                continue

            # The padding for a line goes after its content but before the break
            # that ends it, so the pending run has to be flushed first.
            self.ansi_writer.forward.write(text[byte=line_start:index])
            self.pad()
            self.ansi_writer.reset_ansi()
            self.ansi_writer.forward.write(text[byte = index : index + break_length])

            self.line_len = 0
            index += break_length
            line_start = index

        self.ansi_writer.forward.write(text[byte=line_start:length])

    def _write_classified[origin: ImmOrigin, //](mut self, grapheme: StringSpan[origin], sequence_prefix: Int) -> None:
        """Writes a cluster whose codepoints `step` has already classified.

        Parameters:
            origin: The origin of the grapheme cluster.

        Args:
            grapheme: The cluster to write.
            sequence_prefix: How many of its leading codepoints are sequence content.
        """
        var index = 0
        for codepoint in grapheme.codepoints():
            self.ansi_writer.write_stepped(codepoint, is_sequence=index < sequence_prefix)
            index += 1

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

        return self.ansi_writer^.take()


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
