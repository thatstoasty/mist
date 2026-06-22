from std.benchmark import Bencher

from mist import Profile, dedent, indent, margin, padding, truncate, word_wrap, wrap


@parameter
def bench_indent(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = indent(s, 4)

    b.iter[do]()


@parameter
def bench_dedent(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = dedent(s)

    b.iter[do]()


@parameter
def bench_margin(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = margin(s, 4, 4)

    b.iter[do]()


@parameter
def bench_word_wrap(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = word_wrap(s, 100)

    b.iter[do]()


@parameter
def bench_wrap(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = wrap(s, 100)

    b.iter[do]()


@parameter
def bench_truncate(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = truncate(s, 100)

    b.iter[do]()


@parameter
def bench_padding(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = padding(s, 4)

    b.iter[do]()
