import utils.write
import mist.transform.ansi
import mist.transform.padder as padding
import mist.transform.indenter as indent
from mist.transform.bytes import ByteWriter
from mist.transform.unicode import string_width


struct Writer(Stringable, Writable, Movable):
    """A margin writer that applies a margin to the content.

    Example Usage:
    ```mojo
    from mist.transform import marginer as margin

    fn main():
        var writer = margin.Writer(5, 2)
        writer.write("Hello, World!")
        _ = writer.close()
        print(writer.consume())
    ```
    .
    """

    var buf: ByteWriter
    """The buffer that stores the margin applied content."""
    var pw: padding.Writer
    """The padding `Writer`."""
    var iw: indent.Writer
    """The indent `Writer`."""

    fn __init__(out self, owned pw: padding.Writer, owned iw: indent.Writer):
        """Initializes the `Writer`.

        Args:
            pw: The padding `Writer` instance.
            iw: The indent `Writer` instance.
        """
        self.buf = ByteWriter()
        self.pw = pw^
        self.iw = iw^

    fn __init__(out self, pad: Int, indentation: Int):
        """Initializes a new `Writer`.

        Args:
            pad: Width of the padding of the padding `Writer` instance.
            indentation: Width of the indentation of the padding `Writer` instance.
        """
        self.buf = ByteWriter()
        self.pw = padding.Writer(pad)
        self.iw = indent.Writer(indentation)

    fn __moveinit__(out self, owned other: Self):
        """Constructs a new `Writer` by taking the content of the other `Writer`.

        Args:
            other: The other `Writer` to take the content from.
        """
        self.buf = other.buf^
        self.pw = other.pw^
        self.iw = other.iw^

    fn __str__(self) -> String:
        """Returns the result with margin applied as a string by copying the content of the internal buffer.

        Returns:
            The string with margin applied.
        """
        return String(self.buf)

    fn write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content of the buffer to the specified writer.

        Parameters:
            W: The type of the writer to write to.

        Args:
            writer: The writer to write the content to.
        """
        writer.write(self.buf)

    fn consume(mut self) -> String:
        """Returns the result with margin applied as a string by taking the data from the internal buffer.

        Returns:
            The string with margin applied.
        """
        return self.buf.consume()

    fn as_bytes(self) -> Span[Byte, __origin_of(self.buf)]:
        """Returns the result with margin applied as a Byte Span.

        Returns:
            The result with margin applied as a Byte Span.
        """
        return self.buf.as_bytes()

    fn write(mut self, text: StringSlice) -> None:
        """Writes the text, `content`, to the writer, with the
        padding and indentation applied.

        Args:
            text: The String to write.
        """
        self.iw.write(text)
        self.pw.write(self.iw.consume())

    fn close(mut self):
        """Will finish the margin operation. Always call it before trying to retrieve the final result."""
        self.pw.flush()
        self.buf.write(self.pw.consume())


fn margin(text: StringSlice, width: Int, margin: Int) -> String:
    """Right pads `text` with a `width` number of spaces, and indents it with `margin` spaces.

    Args:
        text: The content to apply the margin to.
        width: The width of the margin.
        margin: The margin to apply.

    Returns:
        A new margin applied string.
    """
    var writer = Writer(width, margin)
    writer.write(text)
    writer.close()
    return writer.consume()
