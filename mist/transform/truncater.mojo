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
    var tail_width: UInt
    """The printable cell width of `tail`, measured once at construction."""
    var cur_width: UInt
    """The printable cell width written so far, accumulated across writes."""
    var truncated: Bool
    """Whether the tail has been emitted and further content is being dropped."""
    var ansi_writer: ansi.Writer
    """The ANSI aware writer that stores the text content."""

    def __init__(out self, width: UInt, var tail: String):
        """Initializes a new truncate-writer instance.

        Args:
            width: The maximum printable cell width.
            tail: The tail to append to the truncated content.
        """
        self.width = width
        self.tail_width = ansi.printable_rune_width(tail)
        self.tail = tail^
        self.cur_width = 0
        self.truncated = False
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
        # The budget and the running total are held on the writer, not derived
        # per call: recomputing them here made each successive `write` grant
        # itself a fresh allowance, so content past the limit survived whenever
        # it arrived in more than one piece.
        if self.truncated:
            return

        if self.width < self.tail_width:
            self.ansi_writer.forward.write(self.tail)
            self.truncated = True
            return

        var budget = self.width - self.tail_width

        for grapheme in text.graphemes():
            # Sequence codepoints always form a prefix of a cluster: `ESC` is a
            # Control character, so it can only ever be a cluster's first
            # codepoint, which means the scanner can leave a sequence partway
            # through a cluster but never enter one. The whole cluster's
            # classification is therefore just the length of that prefix.
            #
            # Classifying through the writer's own scanner, rather than a second
            # one kept in lockstep, means each codepoint is stepped once.
            var sequence_prefix = 0
            for codepoint in grapheme.codepoints():
                if not self.ansi_writer.step(codepoint):
                    break
                sequence_prefix += 1

            var printable = sequence_prefix == 0
            if printable:
                self.cur_width += grapheme_width(grapheme)

                if self.cur_width > budget:
                    self.ansi_writer.forward.write(self.tail)
                    self.ansi_writer.reset_ansi()
                    self.truncated = True
                    return

            # Clusters are written whole. Writing a prefix would emit a partial
            # cluster -- a dangling ZWJ, or an emoji stripped of its skin tone
            # modifier -- which renders differently than the text it came from.
            var index = 0
            for codepoint in grapheme.codepoints():
                self.ansi_writer.write_stepped(codepoint, is_sequence=index < sequence_prefix)
                index += 1


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
