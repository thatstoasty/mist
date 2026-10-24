from std.benchmark import Bencher

from mist import Profile, dedent, indent, margin, padding, truncate, word_wrap, wrap


def bench_indent(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = indent(s, 4)

    b.iter(do)


def bench_dedent(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = dedent(s)

    b.iter(do)


def bench_margin(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = margin(s, 4, 4)

    b.iter(do)


def bench_word_wrap(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = word_wrap(s, 100)

    b.iter(do)


def bench_wrap(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = wrap(s, 100)

    b.iter(do)


def bench_truncate(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = truncate(s, 100)

    b.iter(do)


def bench_padding(mut b: Bencher, s: String) raises:
    @always_inline
    def do() raises {imm s}:
        _ = padding(s, 4)

    b.iter(do)
