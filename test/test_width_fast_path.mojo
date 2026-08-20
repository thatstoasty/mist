"""Differential tests pinning the ASCII width shortcut to the general path.

`string_width` and `printable_rune_width` shortcut plain ASCII by counting
bytes instead of segmenting grapheme clusters. That shortcut is only sound if
it agrees with the general path on every input it accepts, so these tests run
both paths over a corpus and assert they match, rather than restating expected
widths that would drift from the implementation.
"""
from std import testing
from std.testing import TestSuite

from mist.transform.ansi import _ascii_scanned_width, _printable_rune_width_scanned, printable_rune_width
from mist.transform.unicode import _ascii_cell_width, _string_width_graphemes, string_width


def _assert_paths_agree(text: String) raises:
    """Asserts both width functions agree with their general-path counterparts.

    Args:
        text: The input to measure along both paths.
    """
    testing.assert_equal(
        string_width(text),
        _string_width_graphemes(text),
        String("string_width disagrees with the grapheme path for ", repr(text)),
    )
    testing.assert_equal(
        printable_rune_width(text),
        _printable_rune_width_scanned(text),
        String("printable_rune_width disagrees with the scanned path for ", repr(text)),
    )


def test_every_ascii_byte_alone() raises:
    # Each ASCII byte on its own, including the controls and DEL that the
    # shortcut must score as zero-width.
    for i in range(0x00, 0x80):
        _assert_paths_agree(String(Codepoint(unsafe_unchecked_codepoint=UInt32(i))))


def test_every_ascii_byte_between_printables() raises:
    # The same bytes surrounded by content, so a mis-scored byte shows up as a
    # disagreement rather than being masked by an empty result.
    for i in range(0x00, 0x80):
        _assert_paths_agree("a" + String(Codepoint(unsafe_unchecked_codepoint=UInt32(i))) + "b")


def test_every_length_crosses_simd_boundaries() raises:
    # The scan consumes a SIMD register at a time and finishes the remainder
    # byte by byte, so every length up to a few registers must agree -- this is
    # where an off-by-one in the tail would surface.
    var text = String()
    for i in range(200):
        _assert_paths_agree(text)
        text += String(Codepoint(unsafe_unchecked_codepoint=UInt32(0x20 + (i % 95))))


def test_non_ascii_at_every_offset() raises:
    # A multi-byte codepoint anywhere in the span must send both functions down
    # the general path, including when it straddles a SIMD chunk boundary.
    comptime BASE = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()"
    for i in range(BASE.byte_length() + 1):
        _assert_paths_agree(String(BASE[byte=0:i], "é", BASE[byte=i : BASE.byte_length()]))


def test_escape_at_every_offset() raises:
    # Likewise for an escape sequence, which `printable_rune_width` must skip
    # and `string_width` must score as zero-width control bytes.
    comptime BASE = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()"
    for i in range(BASE.byte_length() + 1):
        _assert_paths_agree(String(BASE[byte=0:i], "\x1B[31m", BASE[byte=i : BASE.byte_length()]))


def test_ascii_structure() raises:
    # CRLF is the one ASCII grapheme cluster spanning more than one byte. The
    # shortcut sums its bytes instead of clustering them, which only agrees
    # because both halves are zero-width controls.
    _assert_paths_agree("")
    _assert_paths_agree("\r\n")
    _assert_paths_agree("\r\n\r\n")
    _assert_paths_agree("a\r\nb")
    _assert_paths_agree("a\r\n\r\nb")
    _assert_paths_agree("a\tb")
    _assert_paths_agree("a\nb")
    _assert_paths_agree("  leading and trailing  ")
    _assert_paths_agree("~~~~")


def test_escape_sequences() raises:
    _assert_paths_agree("\x1B[31m\x1B[0m")
    _assert_paths_agree("\x1B[1m\x1B[31mab\x1B[0m")
    _assert_paths_agree("abc\x1B[31")
    _assert_paths_agree("\x1B[2Kabc")
    _assert_paths_agree("a\x1BMb")
    _assert_paths_agree("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!")
    _assert_paths_agree("\x1B]8;;http://example.com\x07link\x1B]8;;\x07")
    _assert_paths_agree("\x1B]8;;http://example.com\x1B\\link\x1B]8;;\x1B\\")
    _assert_paths_agree("\x1B]8;;http://exàmple.com\x07link\x1B]8;;\x07")
    _assert_paths_agree("\x1B")
    _assert_paths_agree("\x1B[")
    _assert_paths_agree("a\x1B")


def test_non_ascii() raises:
    _assert_paths_agree("你好")
    _assert_paths_agree("こんにちは, 世界!")
    _assert_paths_agree("🔥")
    _assert_paths_agree("ábc")
    _assert_paths_agree("❤️")
    _assert_paths_agree("❤︎")
    _assert_paths_agree("a​b")
    _assert_paths_agree("\U0001F468‍\U0001F469‍\U0001F467‍\U0001F466")
    _assert_paths_agree("\U0001F44B\U0001F3FB")
    _assert_paths_agree("\U0001F1FA\U0001F1F8")
    _assert_paths_agree("hi \U0001F525 there")
    _assert_paths_agree("\x1B[31m\U0001F44B\U0001F3FB\x1B[0m")


def test_styled_ascii_takes_the_byte_wise_path() raises:
    # Styled text always contains `ESC`, so the sequence-free shortcut declines
    # it and the byte-wise scan is what actually runs. The agreement tests above
    # would pass even if neither fired, so pin down which path claims what.
    testing.assert_true(Bool(_ascii_scanned_width("\x1b[31mred\x1b[0m")))
    testing.assert_true(Bool(_ascii_scanned_width("plain, no sequences")))
    testing.assert_false(Bool(_ascii_scanned_width("\x1b[31mé\x1b[0m")))
    testing.assert_false(Bool(_ascii_scanned_width("世界")))

    testing.assert_equal(_ascii_scanned_width("\x1b[31mred\x1b[0m").value(), 3)
    testing.assert_equal(_ascii_scanned_width("\x1b[31m\x1b[0m").value(), 0)
    testing.assert_equal(_ascii_scanned_width("a\x1b[2Kb").value(), 2)
    testing.assert_equal(_ascii_scanned_width("\x1b]8;;http://x\x07link\x1b]8;;\x07").value(), 4)


def test_styled_ascii_at_every_simd_boundary() raises:
    # Regression: the byte-wise scan skips whole SIMD registers while outside a
    # sequence, and that skip can land exactly on the end of the span. Reading
    # one byte further then ran off the buffer, which only changed the answer
    # depending on what happened to sit in that byte.
    for length in range(140):
        var run = String()
        for i in range(length):
            run += String(Codepoint(unsafe_unchecked_codepoint=UInt32(0x61 + (i % 26))))

        # Sequence at the front, at the back, and on both sides, so a register
        # skip ends the span from every direction.
        _assert_paths_agree(String("\x1b[31m", run))
        _assert_paths_agree(String(run, "\x1b[0m"))
        _assert_paths_agree(String("\x1b[31m", run, "\x1b[0m"))
        _assert_paths_agree(String(run, "\x1b[0m", run))


def test_shortcut_declines_non_ascii() raises:
    # The agreement tests above still pass if the shortcut never fires, so pin
    # down which inputs it actually accepts.
    testing.assert_true(Bool(_ascii_cell_width[reject_escape=False]("plain ascii")))
    testing.assert_false(Bool(_ascii_cell_width[reject_escape=False]("é")))
    testing.assert_false(Bool(_ascii_cell_width[reject_escape=False]("a very long run of ascii then é")))

    # `ESC` is ordinary zero-width content when measuring everything, but
    # disqualifies the span when sequences have to be skipped.
    testing.assert_true(Bool(_ascii_cell_width[reject_escape=False]("\x1B[31mred")))
    testing.assert_false(Bool(_ascii_cell_width[reject_escape=True]("\x1B[31mred")))


def test_shortcut_counts_printable_cells() raises:
    testing.assert_equal(_ascii_cell_width[reject_escape=True]("").value(), 0)
    testing.assert_equal(_ascii_cell_width[reject_escape=True]("abc").value(), 3)

    # Controls and DEL occupy no cells.
    testing.assert_equal(_ascii_cell_width[reject_escape=True]("a\tb\nc\x7Fd").value(), 4)

    # A run long enough to exercise the SIMD loop and the scalar tail together.
    testing.assert_equal(_ascii_cell_width[reject_escape=True]("x" * 100 + "\n" + "y" * 37).value(), 137)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
