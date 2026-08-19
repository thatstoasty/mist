from std import testing
from mist.transform.ansi import SequenceScanner, Writer, is_terminator, printable_rune_width
from std.testing import TestSuite


def test_is_terminator() raises:
    # Every CSI final byte terminates a sequence -- not just ASCII letters.
    # The full final-byte range is 0x40-0x7E: letters, and `@[\\]^_\`{|}~`.
    for codepoint in "mK@Z[\\]^_`az{|}~".codepoints():
        testing.assert_true(is_terminator(codepoint))

    # Parameter and intermediate bytes do not terminate a sequence.
    for codepoint in "0;?<>! ".codepoints():
        testing.assert_false(is_terminator(codepoint))


def test_printable_rune_length() raises:
    testing.assert_equal(printable_rune_width("🔥"), 2)
    testing.assert_equal(printable_rune_width("こんにちは, 世界!"), 17)
    testing.assert_equal(printable_rune_width("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!"), 19)


def test_printable_rune_width_edge_cases() raises:
    # Empty string has no width.
    testing.assert_equal(printable_rune_width(""), 0)

    # A string of only escape sequences is entirely non-printable.
    testing.assert_equal(printable_rune_width("\x1B[31m\x1B[0m"), 0)

    # Adjacent sequences are each skipped in full.
    testing.assert_equal(printable_rune_width("\x1B[1m\x1B[31mab\x1B[0m"), 2)

    # A truncated sequence at the end of the input swallows the remainder.
    testing.assert_equal(printable_rune_width("abc\x1B[31"), 3)

    # Non-SGR CSI sequences are skipped just like color codes.
    testing.assert_equal(printable_rune_width("\x1B[2Kabc"), 3)

    # Control characters occupy no cells.
    testing.assert_equal(printable_rune_width("a\tb"), 2)
    testing.assert_equal(printable_rune_width("a\nb"), 2)

    # Zero-width space contributes nothing.
    testing.assert_equal(printable_rune_width("a​b"), 2)


def test_printable_rune_width_osc8_hyperlink() raises:
    # OSC 8 hyperlinks are terminated by BEL, not by a letter. A naive
    # "next letter ends the sequence" scan would stop at the `h` in `http`
    # and count the rest of the URL as printable text.
    testing.assert_equal(printable_rune_width("\x1B]8;;http://example.com\x07link\x1B]8;;\x07"), 4)

    # The string terminator form (`ESC \\`) is recognized too.
    testing.assert_equal(printable_rune_width("\x1B]8;;http://example.com\x1B\\link\x1B]8;;\x1B\\"), 4)


def test_printable_rune_width_two_byte_escape() raises:
    # A bare two-byte escape (not CSI, not a string type) consumes just the
    # two bytes and nothing after it.
    testing.assert_equal(printable_rune_width("a\x1BMb"), 2)


def test_printable_rune_width_grapheme_clusters() raises:
    # Width is measured per grapheme cluster, so a ZWJ-joined emoji counts
    # once rather than once per joined codepoint -- with or without styling
    # wrapped around it.
    comptime FAMILY = "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"
    testing.assert_equal(printable_rune_width(FAMILY), 2)
    testing.assert_equal(printable_rune_width("\x1B[31m" + FAMILY + "\x1B[0m"), 2)

    # Skin tone modifiers and flags likewise render as one cluster.
    testing.assert_equal(printable_rune_width("\x1B[31m\U0001F44B\U0001F3FB\x1B[0m"), 2)
    testing.assert_equal(printable_rune_width("\U0001F1FA\U0001F1F8"), 2)


def test_printable_rune_width_non_ascii_inside_sequence() raises:
    # Non-ASCII bytes inside a string sequence (a UTF-8 URL in an OSC 8
    # hyperlink) are part of the sequence, not visible content. The width scan
    # used to bypass the sequence scanner for any multi-byte codepoint, so
    # these were measured as if they were printable.
    testing.assert_equal(printable_rune_width("\x1B]8;;http://\u4f8b\u3048.com\x07link\x1B]8;;\x07"), 4)


def test_sequence_scanner_csi() raises:
    var scanner = SequenceScanner()
    testing.assert_false(scanner.step(Codepoint(UInt8(ord("a")))))
    for c in "\x1B[31m".codepoints():
        testing.assert_true(scanner.step(c))
    testing.assert_false(scanner.is_active())
    testing.assert_false(scanner.step(Codepoint(UInt8(ord("b")))))


def test_sequence_scanner_osc_bel_terminated() raises:
    var scanner = SequenceScanner()
    for c in "\x1B]8;;http://x\x07".codepoints():
        testing.assert_true(scanner.step(c))
    testing.assert_false(scanner.is_active())


def test_sequence_scanner_osc_string_terminator() raises:
    var scanner = SequenceScanner()
    for c in "\x1B]8;;http://x\x1B\\".codepoints():
        testing.assert_true(scanner.step(c))
    testing.assert_false(scanner.is_active())


def test_sequence_scanner_two_byte_escape() raises:
    # A two-byte escape (e.g. `ESC M`) terminates immediately after the
    # second byte, without needing a CSI-style final byte.
    var scanner = SequenceScanner()
    testing.assert_true(scanner.step(Codepoint(UInt8(ord("\x1B")))))
    testing.assert_true(scanner.step(Codepoint(UInt8(ord("M")))))
    testing.assert_false(scanner.is_active())


def test_writer_round_trip() raises:
    # Writing content with no transformation applied must reproduce the input
    # byte for byte, sequences included.
    comptime CONTENT = "I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!"
    var writer = Writer()
    writer.write(CONTENT)
    testing.assert_equal(writer.forward, CONTENT)


def test_writer_does_not_repeat_sequences() raises:
    # Regression: the sequence buffer used to accumulate across the whole input,
    # so every sequence after the first re-emitted all of its predecessors.
    var writer = Writer()
    writer.write("\x1B[90mMilky\x1B[0m")
    testing.assert_equal(writer.forward, "\x1B[90mMilky\x1B[0m")

    # Several sequences in a row, each written exactly once.
    var multi = Writer()
    multi.write("\x1B[1m\x1B[31mA\x1B[0m\x1B[32mB\x1B[0m")
    testing.assert_equal(multi.forward, "\x1B[1m\x1B[31mA\x1B[0m\x1B[32mB\x1B[0m")


def test_writer_last_sequence() raises:
    var writer = Writer()
    testing.assert_equal(String(writer.last_sequence()), "")

    # SGR sequences accumulate, since terminal styling is cumulative.
    writer.write("\x1B[1m")
    testing.assert_equal(String(writer.last_sequence()), "\x1B[1m")
    writer.write("\x1B[31m")
    testing.assert_equal(String(writer.last_sequence()), "\x1B[1m\x1B[31m")

    # A reset sequence clears the accumulated style.
    writer.write("\x1B[0m")
    testing.assert_equal(String(writer.last_sequence()), "")


def test_writer_last_sequence_ignores_non_sgr() raises:
    # Non-SGR CSI sequences are not styling, so they are not recorded.
    var writer = Writer()
    writer.write("\x1B[2K")
    testing.assert_equal(String(writer.last_sequence()), "")
    testing.assert_equal(writer.forward, "\x1B[2K")


def test_reset_ansi() raises:
    var writer = Writer()
    writer.reset_ansi()
    testing.assert_equal(String(writer.forward), "")
    writer.seq_changed = True
    writer.reset_ansi()
    testing.assert_equal(String(writer.forward), "\x1b[0m")


def test_reset_ansi_after_write() raises:
    # Writing a style marks the sequence as changed, so a reset is emitted.
    var writer = Writer()
    writer.write("\x1B[31mfoo")
    writer.reset_ansi()
    testing.assert_equal(writer.forward, "\x1B[31mfoo\x1B[0m")

    # After an explicit reset in the content, there is nothing left to reset.
    var already_reset = Writer()
    already_reset.write("\x1B[31mfoo\x1B[0m")
    already_reset.reset_ansi()
    testing.assert_equal(already_reset.forward, "\x1B[31mfoo\x1B[0m")


def test_restore_ansi() raises:
    var writer = Writer()
    writer.last_seq = String("\x1b[38;2;249;38;114m")
    writer.restore_ansi()
    testing.assert_equal(writer.forward, "\x1b[38;2;249;38;114m")


def test_restore_ansi_replays_accumulated_style() raises:
    # Restoring replays every attribute that is still in effect.
    var writer = Writer()
    writer.write("\x1B[1m\x1B[31mfoo")
    writer.restore_ansi()
    testing.assert_equal(writer.forward, "\x1B[1m\x1B[31mfoo\x1B[1m\x1B[31m")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
