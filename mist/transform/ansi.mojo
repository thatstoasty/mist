from io import write

from mist.transform.unicode import char_width, string_width


comptime ANSI_ESCAPE = "[0m"
"""The ANSI escape sequence for resetting formatting."""
comptime ANSI_MARKER = "\x1b"
"""The ANSI escape sequence marker."""
comptime ANSI_MARKER_BYTE = ord(ANSI_MARKER)
"""The byte value of the ANSI escape sequence marker."""
comptime SGR_COMMAND = ord("m")
"""The byte value of the SGR command."""
comptime SPACE = " "
"""A single space character."""
comptime NEWLINE = "\n"
"""A newline character."""
comptime TAB_BYTE = ord("\t")
"""The byte value of the tab character."""
comptime SPACE_BYTE = ord(" ")
"""The byte value of the space character."""
comptime NEWLINE_BYTE = ord("\n")
"""The byte value of the newline character."""


fn equals(left: Span[Byte], right: Span[Byte]) -> Bool:
    """Reports if `left` and `right` are equal.

    Args:
        left: The first bytes to compare.
        right: The second bytes to compare.

    Returns:
        True if the bytes are equal, False otherwise.
    """
    if len(left) != len(right):
        return False

    for i in range(len(left)):
        if left[i] != right[i]:
            return False
    return True


fn has_suffix(bytes: Span[Byte], suffix: Span[Byte]) -> Bool:
    """Reports if the list ends with suffix.

    Args:
        bytes: The bytes to search.
        suffix: The suffix to search for.

    Returns:
        True if the bytes end with the suffix, False otherwise.
    """
    if len(bytes) < len(suffix):
        return False

    if not equals(bytes[len(bytes) - len(suffix) : len(bytes)], suffix):
        return False
    return True


fn is_terminator(c: Codepoint) -> Bool:
    """Reports if the rune is a terminator.

    Args:
        c: The rune to check.

    Returns:
        True if the rune is a terminator, False otherwise.
    """
    var rune = c.to_u32()
    return (rune >= 0x40 and rune <= 0x5A) or (rune >= 0x61 and rune <= 0x7A)


fn printable_rune_width(text: StringSlice) -> UInt:
    """Returns the cell width of the given string.

    Args:
        text: String to calculate the width of.

    Returns:
        The printable cell width of the string.
    """
    var length: UInt = 0
    var ansi = False

    for codepoint in text.codepoints():
        if codepoint.utf8_byte_length() > 1:
            length += char_width(codepoint)
            continue

        if codepoint.to_u32() == ANSI_MARKER_BYTE:
            # ANSI escape sequence
            ansi = True
        elif ansi:
            if is_terminator(codepoint):
                # ANSI sequence terminated
                ansi = False
        else:
            length += char_width(codepoint)

    return length


@fieldwise_init
struct Writer(Movable, Writable):
    """A writer that handles ANSI escape sequences in the content.

    #### Examples:
    ```mojo
    from mist.transform import ansi

    fn main():
        var writer = ansi.Writer()
        writer.write("Hello, World!")
        print(writer)
    ```
    """

    var forward: String
    """The buffer that stores the text content."""
    var ansi: Bool
    """Whether the current character is part of an ANSI escape sequence."""
    var ansi_seq: String
    """The buffer that stores the ANSI escape sequence."""
    var last_seq: String
    """The buffer that stores the last ANSI escape sequence."""
    var seq_changed: Bool
    """Whether the ANSI escape sequence has changed."""

    fn __init__(out self, var forward: String = String()):
        """Initializes a new ANSI-writer instance.

        Args:
            forward: The buffer that stores the text content.
        """
        self.forward = forward^
        self.ansi = False
        self.ansi_seq = String(capacity=128)
        self.last_seq = String(capacity=128)
        self.seq_changed = False

    fn write_to[W: write.Writer, //](self, mut writer: W):
        """Writes the content to the given writer.

        Parameters:
            W: The type of the writer.

        Args:
            writer: The writer to write to.
        """
        writer.write(self.forward)

    fn write(mut self, content: StringSlice) -> None:
        """Write content to the ANSI buffer.

        Args:
            content: The content to write.
        """
        for codepoint in content.codepoints():
            self.write(codepoint)

    fn write(mut self, codepoint: Codepoint) -> None:
        """Write codepoint to the ANSI buffer.

        Args:
            codepoint: The content to write.
        """
        # ANSI escape sequence
        if codepoint.to_u32() == ANSI_MARKER_BYTE:
            self.ansi = True
            self.seq_changed = True
            self.ansi_seq.write(codepoint)
        elif self.ansi:
            self.ansi_seq.write(codepoint)
            if is_terminator(codepoint):
                self.ansi = False
                if self.ansi_seq.as_string_slice().startswith(ANSI_ESCAPE):
                    # reset sequence
                    self.last_seq = String(capacity=self.last_seq.capacity())
                    self.seq_changed = False
                elif codepoint.to_u32() == SGR_COMMAND:
                    # color code
                    self.last_seq.write(self.ansi_seq)

                self.forward.write(self.ansi_seq)
        else:
            self.forward.write(codepoint)

    fn last_sequence(self) -> StringSlice[origin_of(self.last_seq)]:
        """Returns the last ANSI escape sequence.

        Returns:
            The last ANSI escape sequence.
        """
        return StringSlice(self.last_seq)

    fn reset_ansi(mut self) -> None:
        """Resets the ANSI escape sequence."""
        if not self.seq_changed:
            return

        self.forward.write(ANSI_MARKER + ANSI_ESCAPE)

    fn restore_ansi(mut self) -> None:
        """Restores the last ANSI escape sequence."""
        self.forward.write(self.last_seq)
