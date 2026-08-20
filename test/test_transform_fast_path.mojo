"""Differential tests pinning the ASCII transform shortcuts to the general paths.

Each writer walks plain ASCII a byte at a time instead of segmenting grapheme
clusters, on the reasoning that in ASCII every byte is its own cluster apart
from `CRLF`. That shortcut is only sound if it produces exactly what the
general path produces, so these tests drive both and compare, rather than
restating expected output that would drift from the implementation.

`CRLF` is the case worth the attention: the byte-wise paths pair it explicitly,
and pairing it wrongly reorders inserted padding, indentation, or line breaks
around the two halves of the break.
"""
from std import testing
from std.testing import TestSuite

from mist.transform import indent, padding, truncate, word_wrap, wrap
from mist.transform.ansi import printable_rune_width
from mist.transform.indenter import IndentWriter
from mist.transform.padder import PaddingWriter
from mist.transform.word_wrapper import WordWrapWriter
from mist.transform.wrapper import WrapWriter


def _ascii_corpus() -> List[String]:
    """Builds the plain-ASCII inputs both paths must agree on.

    Returns:
        The corpus of ASCII strings to drive through both paths.
    """
    var out: List[String] = [
        String(""),
        String("a"),
        String("hello world"),
        String("the quick brown fox jumps over the lazy dog"),
        String(" "),
        String("   "),
        String("\t"),
        String("\n"),
        String("\r\n"),
        String("\r"),
        String("x\ry"),
        String("\r\r\n\r"),
        String("\n\n\n"),
        String("a\n\nb"),
        String("trailing\n"),
        String("\nleading"),
        String("a\r\nb\r\nc"),
        String("\r\n\r\n"),
        String("mixed\nbreaks\r\nhere\n"),
        String("  indented\n    more\n  back"),
        String("a b c d e f g h i j k l m n o p"),
        String("supercalifragilisticexpialidocious"),
        String("word-with-breakpoint-chars"),
        String("trailing spaces   \n   leading"),
        String("a\x7Fb"),
        String("ctrl\x01chars\x02here"),
    ]

    # A newline, a CRLF, and a lone CR at every offset of a medium string, so a
    # mispaired break shows up wherever it can occur -- including across the
    # boundaries of the SIMD scan that classifies the span.
    comptime BASE = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJ"
    for i in range(BASE.byte_length() + 1):
        var head = BASE[byte=0:i]
        var tail = BASE[byte=i : BASE.byte_length()]
        out.append(String(head, "\n", tail))
        out.append(String(head, "\r\n", tail))
        out.append(String(head, "\r", tail))
        out.append(String(head, "  ", tail))

    # Every length across a few SIMD registers.
    for length in range(140):
        var run = String()
        for i in range(length):
            run += String(Codepoint(unsafe_unchecked_codepoint=UInt32(0x20 + (i % 95))))
        out.append(run^)

    return out^


def _assert_padding_agrees(text: String, width: UInt) raises:
    """Asserts both `PaddingWriter` paths produce the same output.

    Args:
        text: The content to pad.
        width: The padding width.
    """
    var fast = PaddingWriter(width)
    fast._write_ascii(text)

    var general = PaddingWriter(width)
    general._write_general(text)

    testing.assert_equal(
        fast^.finish(),
        general^.finish(),
        String("padding(", repr(text), ", ", width, ") differs between paths"),
    )


def _assert_indent_agrees(text: String, width: UInt) raises:
    """Asserts both `IndentWriter` paths produce the same output.

    Args:
        text: The content to indent.
        width: The indent width.
    """
    var fast = IndentWriter(width)
    fast._write_ascii(text)

    var general = IndentWriter(width)
    general._write_general(text)

    testing.assert_equal(
        String(fast),
        String(general),
        String("indent(", repr(text), ", ", width, ") differs between paths"),
    )


def _assert_wrap_agrees(text: String, limit: UInt) raises:
    """Asserts both `WrapWriter` paths produce the same output.

    Args:
        text: The content to wrap.
        limit: The maximum line length.
    """
    var fast = WrapWriter(limit)
    fast._write_ascii(text)

    var general = WrapWriter(limit)
    general._write_general(text)

    testing.assert_equal(
        String(fast),
        String(general),
        String("wrap(", repr(text), ", ", limit, ") differs between paths"),
    )


def _assert_word_wrap_agrees(text: String, limit: UInt) raises:
    """Asserts both `WordWrapWriter` paths produce the same output.

    Args:
        text: The content to wrap.
        limit: The maximum line length.
    """
    var fast = WordWrapWriter(limit)
    fast._write_ascii(text)

    var general = WordWrapWriter(limit)
    general._write_general(text)

    testing.assert_equal(
        fast^.finish(),
        general^.finish(),
        String("word_wrap(", repr(text), ", ", limit, ") differs between paths"),
    )


def test_padding_paths_agree() raises:
    var corpus = _ascii_corpus()
    for i in range(len(corpus)):
        for width in [UInt(0), UInt(1), UInt(5), UInt(20), UInt(60)]:
            _assert_padding_agrees(corpus[i], width)


def test_indent_paths_agree() raises:
    var corpus = _ascii_corpus()
    for i in range(len(corpus)):
        for width in [UInt(0), UInt(1), UInt(4), UInt(20)]:
            _assert_indent_agrees(corpus[i], width)


def test_wrap_paths_agree() raises:
    var corpus = _ascii_corpus()
    for i in range(len(corpus)):
        for limit in [UInt(1), UInt(2), UInt(5), UInt(20), UInt(60)]:
            _assert_wrap_agrees(corpus[i], limit)


def test_word_wrap_paths_agree() raises:
    var corpus = _ascii_corpus()
    for i in range(len(corpus)):
        for limit in [UInt(1), UInt(2), UInt(5), UInt(20), UInt(60)]:
            _assert_word_wrap_agrees(corpus[i], limit)


def test_crlf_is_paired_not_split() raises:
    # The whole reason the byte-wise paths pair CRLF: padding goes after a
    # line's content but before the break that ends it, so treating CR and LF
    # as two clusters would wedge the padding between them.
    _assert_padding_agrees("ab\r\ncd\r\n", 6)
    _assert_padding_agrees("\r\n", 4)
    _assert_padding_agrees("a\r\n", 4)
    _assert_indent_agrees("ab\r\ncd\r\n", 3)
    _assert_wrap_agrees("ab\r\ncd\r\n", 3)
    _assert_word_wrap_agrees("ab\r\ncd\r\n", 3)

    # A lone CR is not a line break and must not be mistaken for one.
    _assert_padding_agrees("ab\rcd", 6)
    _assert_indent_agrees("ab\rcd", 3)
    _assert_wrap_agrees("ab\rcd", 3)
    _assert_word_wrap_agrees("ab\rcd", 3)

    # A CR at the very end has no LF to pair with and must not read past it.
    _assert_padding_agrees("ab\r", 6)
    _assert_indent_agrees("ab\r", 3)
    _assert_wrap_agrees("ab\r", 3)
    _assert_word_wrap_agrees("ab\r", 3)


def test_zero_width_bytes_do_not_advance_the_line() raises:
    # Controls and DEL occupy no cells, so they must not count toward a limit
    # or toward a padded line's length.
    _assert_padding_agrees("a\x01b\x7Fc", 8)
    _assert_wrap_agrees("a\x01b\x7Fc", 2)
    _assert_word_wrap_agrees("a\x01b\x7Fc", 2)


def test_straddling_clusters_survive_classification() raises:
    # A cluster can span the end of a sequence: `\x1b[31` + `m` + U+0301 puts
    # the CSI final byte and a combining mark in one cluster. The writers
    # classify such a cluster by the length of its sequence prefix, so these
    # pin the results that reasoning has to reproduce.
    testing.assert_equal(indent("\x1b[31ḿabc", 2), "\x1b[31ḿa  bc")
    testing.assert_equal(padding("\x1b[31ḿabc", 10), "\x1b[31ḿabc        ")
    testing.assert_equal(truncate("\x1b[31ḿabc", 3, "."), "\x1b[31ḿabc")
    testing.assert_equal(wrap("\x1b[31ḿabc", 3), "\x1b[31ḿabc")
    testing.assert_equal(word_wrap("\x1b[31ḿabc", 3), "\x1b[31ḿabc")
    testing.assert_equal(printable_rune_width("\x1b[31ḿabc"), 2)

    # The sequence swallows the rest when its final byte never arrives.
    testing.assert_equal(printable_rune_width("\x1b[1ḿx\x1b[0ḿy"), 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
