import mist.transform.ansi
from mist.transform.indenter import IndentWriter
from mist.transform.padder import PaddingWriter
from mist.transform.unicode import string_width


@explicit_destroy("Call finish() to retrieve the final result and destroy the writer.")
struct MarginWriter(Movable):
    """A margin writer that applies a margin to the content.

    #### Examples:
    ```mojo
    from mist.transform import marginer as margin

    fn main():
        var writer = margin.MarginWriter(5, 2)
        writer.write("Hello, World!")
        print(writer^.finish())
    ```
    """

    var buf: String
    """The buffer that stores the margin applied content."""
    var pw: PaddingWriter
    """The padding `Writer`."""
    var iw: IndentWriter
    """The indent `Writer`."""

    fn __init__(out self, var pw: PaddingWriter, var iw: IndentWriter):
        """Initializes the `Writer`.

        Args:
            pw: The padding `Writer` instance.
            iw: The indent `Writer` instance.
        """
        self.buf = String()
        self.pw = pw^
        self.iw = iw^

    fn __init__(out self, pad: UInt, indentation: UInt):
        """Initializes a new `Writer`.

        Args:
            pad: Width of the padding of the padding `Writer` instance.
            indentation: Width of the indentation of the indent `IndentWriter` instance.
        """
        self.buf = String()
        self.pw = PaddingWriter(pad)
        self.iw = IndentWriter(indentation)

    fn write(mut self, text: StringSlice) -> None:
        """Writes the text, `content`, to the writer, with the
        padding and indentation applied.

        Args:
            text: The String to write.
        """
        self.iw.write(text)
        self.pw.write(self.iw.as_string_slice())

    fn finish(deinit self) -> String:
        """Will finish the margin operation. Always call it before trying to retrieve the final result.

        Returns:
            The final margin applied string.
        """
        self.buf.write(self.pw^.finish())
        return self.buf^


fn margin(text: StringSlice, pad: UInt, indent: UInt) -> String:
    """Right pads `text` with a `width` number of spaces, and indents it with `margin` spaces.

    Args:
        text: The content to apply the margin to.
        pad: The width of the padding.
        indent: The width of the indentation to apply.

    Returns:
        A new margin applied string.

    #### Examples:
    ```mojo
    from mist.transform import margin

    fn main():
        print(margin("Hello, World!", pad=5, indent=2))
    ```
    """
    var writer = MarginWriter(pad, indent)
    writer.write(text)
    return writer^.finish()
