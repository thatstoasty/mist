"""A writer that applies both indentation and padding as a margin."""
from mist.transform import ansi
from mist.transform.indenter import IndentWriter
from mist.transform.padder import PaddingWriter
from mist.transform.unicode import string_width


@explicit_destroy("Call finish() to retrieve the final result and destroy the writer.")
struct MarginWriter(Deinitable where False, Movable):
    """A margin writer that applies a margin to the content.

    #### Examples:
    ```mojo
    from mist.transform import marginer as margin

    def main():
        var writer = margin.MarginWriter(5, 2)
        writer.write("Hello, World!")
        print(writer^.finish())
    ```
    """

    var pw: PaddingWriter
    """The padding `Writer`."""
    var iw: IndentWriter
    """The indent `Writer`."""
    var forwarded: Int
    """How many bytes of the indent buffer have already been handed to the padder."""

    def __init__(out self, var pw: PaddingWriter, var iw: IndentWriter):
        """Initializes the `Writer`.

        Args:
            pw: The padding `Writer` instance.
            iw: The indent `Writer` instance.
        """
        self.pw = pw^
        self.iw = iw^
        self.forwarded = 0

    def __init__(out self, pad: UInt, indentation: UInt):
        """Initializes a new `Writer`.

        Args:
            pad: Width of the padding of the padding `Writer` instance.
            indentation: Width of the indentation of the indent `IndentWriter` instance.
        """
        self.pw = PaddingWriter(pad)
        self.iw = IndentWriter(indentation)
        self.forwarded = 0

    def write[origin: ImmOrigin, //](mut self, text: StringSpan[origin]) -> None:
        """Writes the text, `content`, to the writer, with the
        padding and indentation applied.

        Args:
            text: The String to write.
        """
        self.iw.write(text)

        # The indent buffer accumulates across calls, so only the bytes this
        # call appended may go to the padder. Handing it the whole buffer each
        # time re-padded everything written so far, duplicating earlier lines
        # and making repeated writes quadratic.
        var indented = self.iw.as_string_slice()
        self.pw.write(indented[byte = self.forwarded : indented.byte_length()])
        self.forwarded = indented.byte_length()

    def finish(deinit self) -> String:
        """Will finish the margin operation. Always call it before trying to retrieve the final result.

        Returns:
            The final margin applied string.
        """
        return self.pw^.finish()


def margin[origin: ImmOrigin, //](text: StringSpan[origin], pad: UInt, indent: UInt) -> String:
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

    def main():
        print(margin("Hello, World!", pad=5, indent=2))
    ```
    """
    if pad == 0 and indent == 0:
        return String(text)

    var writer = MarginWriter(pad, indent)
    writer.write(text)
    return writer^.finish()
