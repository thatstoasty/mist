import testing
from mist.transform.ansi import Writer, is_terminator, printable_rune_width
from mist.transform.bytes import ByteWriter


def test_is_terminator():
    for codepoint in "m".as_string_slice().codepoints():
        testing.assert_true(is_terminator(codepoint))


def test_printable_rune_length():
    testing.assert_equal(printable_rune_width("🔥"), 2)
    testing.assert_equal(printable_rune_width("こんにちは, 世界!"), 17)
    testing.assert_equal(printable_rune_width("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!"), 19)


# def test_writer():
#     var writer = Writer()
#     writer.write("I really \x1B[38;2;249;38;114mlove\x1B[0m Mojo!")
#     testing.assert_equal(len(writer.forward), 19)
#     testing.assert_equal(len(writer.last_seq), 10)


def test_writer_last_sequence():
    var writer = Writer()
    testing.assert_equal(String(writer.last_sequence()), "")


def test_reset_ansi():
    var writer = Writer()
    writer.reset_ansi()
    testing.assert_equal(String(writer.forward), "")
    writer.seq_changed = True
    writer.reset_ansi()
    testing.assert_equal(String(writer.forward), "\x1b[0m")


def test_restore_ansi():
    var writer = Writer()
    writer.last_seq = ByteWriter("\x1b[38;2;249;38;114m")
    writer.restore_ansi()
    testing.assert_equal(writer.forward.as_string_slice(), "\x1b[38;2;249;38;114m")
