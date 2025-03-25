import utils.write
from utils import StringSlice
from memory import Span
import mist.transform.ansi
from mist.transform.bytes import ByteWriter
from mist.transform.traits import AsStringSlice
from mist.transform.unicode import char_width
from mist.transform.ansi import SPACE, NEWLINE_BYTE, SPACE_BYTE

alias DEFAULT_NEWLINE = "\n"
alias DEFAULT_TAB_WIDTH = 4


struct Writer[keep_newlines: Bool = True](Stringable, Writable, Movable):
    """A line wrapping writer that wraps content based on the given limit.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    Example Usage:
    ```mojo
    from weave import wrapper as wrap

    fn main():
        var writer = wrap.Writer(5)
        writer.write("Hello, World!")
        print(writer.consume())
    ```
    """

    var limit: Int
    """The maximum number of characters per line."""
    var newline: String
    """The character to use as a newline."""
    var preserve_space: Bool
    """Whether to preserve space characters."""
    var tab_width: Int
    """The width of a tab character."""
    var buf: ByteWriter
    """The buffer that stores the wrapped content."""
    var line_len: Int
    """The current line length."""
    var ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""
    var forceful_newline: Bool
    """Whether to force a newline at the end of the line."""

    fn __init__(
        out self,
        limit: Int,
        *,
        newline: String = DEFAULT_NEWLINE,
        preserve_space: Bool = False,
        tab_width: Int = DEFAULT_TAB_WIDTH,
        line_len: Int = 0,
        ansi: Bool = False,
        forceful_newline: Bool = False,
    ):
        """Initializes a new line wrap writer.

        Args:
            limit: The maximum number of characters per line.
            newline: The character to use as a newline.
            preserve_space: Whether to preserve space characters.
            tab_width: The width of a tab character.
            line_len: The current line length.
            ansi: Whether the current character is part of an ANSI escape sequence.
            forceful_newline: Whether to force a newline at the end of the line.
        """
        self.limit = limit
        self.newline = newline
        self.preserve_space = preserve_space
        self.tab_width = tab_width
        self.buf = ByteWriter()
        self.line_len = line_len
        self.ansi = ansi
        self.forceful_newline = forceful_newline

    fn __moveinit__(out self, owned other: Self):
        """Constructs a new `Writer` by taking the content of the other `Writer`.

        Args:
            other: The other `Writer` to take the content from.
        """
        self.limit = other.limit
        self.newline = other.newline
        self.preserve_space = other.preserve_space
        self.tab_width = other.tab_width
        self.buf = other.buf^
        self.line_len = other.line_len
        self.ansi = other.ansi
        self.forceful_newline = other.forceful_newline

    fn __str__(self) -> String:
        """Returns the wrapped result as a string by copying the content of the internal buffer.

        Returns:
            The wrapped string.
        """
        return String(self.buf)

    fn write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content of the buffer to the specified writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write the content to.
        """
        writer.write(self.buf)

    fn consume(mut self) -> String:
        """Returns the wrapped result as a string by taking the data from the internal buffer.

        Returns:
            The wrapped string.
        """
        return self.buf.consume()

    fn as_bytes(self) -> Span[Byte, __origin_of(self.buf)]:
        """Returns the result as a byte span.

        Returns:
            The wrapped result as a byte span.
        """
        return self.buf.as_bytes()

    fn add_newline(mut self) -> None:
        """Adds a newline to the buffer and resets the line length."""
        self.buf.write(self.newline)
        self.line_len = 0

    fn _write(mut self, text: StringSlice) -> None:
        """Writes the text, `content`, to the writer, wrapping lines once the limit is reached.

        Args:
            text: The text to write to the writer.
        """
        var content = String(text)
        var tab_space = SPACE * self.tab_width
        content = content.replace("\t", tab_space)

        @parameter
        if not keep_newlines:
            content = content.replace("\n", "")

        var width = ansi.printable_rune_width(content)
        if self.limit <= 0 or self.line_len + width <= self.limit:
            self.line_len += width
            self.buf.write(content)
            return

        for codepoint in content.codepoints():
            if codepoint.to_u32() == ansi.ANSI_MARKER_BYTE:
                self.ansi = True
            elif self.ansi:
                if ansi.is_terminator(codepoint):
                    self.ansi = False
            elif codepoint.to_u32() == NEWLINE_BYTE:
                self.add_newline()
                self.forceful_newline = False
                continue
            else:
                var width = char_width(codepoint)

                if self.line_len + width > self.limit:
                    self.add_newline()
                    self.forceful_newline = True

                if self.line_len == 0:
                    if self.forceful_newline and not self.preserve_space and codepoint.to_u32() == SPACE_BYTE:
                        continue
                else:
                    self.forceful_newline = False

                self.line_len += width
            self.buf.write(codepoint)

    fn write(mut self, content: StringLiteral) -> None:
        """Writes the text, `content`, to the writer, wrapping lines once the limit is reached.

        Args:
            content: The text to write to the writer.
        """
        self._write(content.as_string_slice())

    fn write[T: AsStringSlice, //](mut self, content: T) -> None:
        """Writes the text, `content`, to the writer, wrapping lines once the limit is reached.

        Parameters:
            T: The type of the Stringable object to dedent.

        Args:
            content: The text to write to the writer.
        """
        self._write(content.as_string_slice())


fn wrap[
    keep_newlines: Bool = True
](
    text: StringLiteral,
    limit: Int,
    *,
    newline: String = DEFAULT_NEWLINE,
    preserve_space: Bool = False,
    tab_width: Int = DEFAULT_TAB_WIDTH,
) -> String:
    """Wraps `text` at `limit` characters per line.

    Parameters:
        keep_newlines: Whether to keep newlines in the content.

    Args:
        text: The string to wrap.
        limit: The maximum line length before wrapping.
        newline: The character to use as a newline.
        preserve_space: Whether to preserve space characters.
        tab_width: The width of a tab character.

    Returns:
        A new wrapped string.

    ```mojo
    from weave import wrap

    fn main():
        var wrapped = wrap("Hello, World!", 5)
        print(wrapped)
    ```
    .
    """
    var writer = Writer[keep_newlines=keep_newlines](
        limit, newline=newline, preserve_space=preserve_space, tab_width=tab_width
    )
    writer.write(text)
    return writer.consume()


fn wrap[
    T: AsStringSlice, //, keep_newlines: Bool = True
](
    text: T,
    limit: Int,
    *,
    newline: String = DEFAULT_NEWLINE,
    preserve_space: Bool = False,
    tab_width: Int = DEFAULT_TAB_WIDTH,
) -> String:
    """Wraps `text` at `limit` characters per line.

    Parameters:
        T: The type of the Stringable object to dedent.
        keep_newlines: Whether to keep newlines in the content.

    Args:
        text: The string to wrap.
        limit: The maximum line length before wrapping.
        newline: The character to use as a newline.
        preserve_space: Whether to preserve space characters.
        tab_width: The width of a tab character.

    Returns:
        A new wrapped string.

    ```mojo
    from weave import wrap

    fn main():
        var wrapped = wrap("Hello, World!", 5)
        print(wrapped)
    ```
    .
    """
    var writer = Writer[keep_newlines=keep_newlines](
        limit, newline=newline, preserve_space=preserve_space, tab_width=tab_width
    )
    writer.write(text)
    return writer.consume()
