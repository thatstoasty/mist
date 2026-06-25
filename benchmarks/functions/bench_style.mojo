from std.benchmark import Bencher

import mist
from mist.style.color import ANSI256Color, ANSIColor, RGBColor
from mist import Profile

# def bench_render_big_file():
#     var content: String = ""
#     try:
#         with open("./benchmarks/data/big.txt", "r") as file:
#             content = file.read()
#             var output = mist.render_as_color(content, 0xC9A0DC)
#             _ = output
#     except e:
#         print(e)

# Render string benchmarks

@parameter
def bench_render_ascii(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.ASCII).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
def bench_render_ascii_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.ASCII.color(0xC9A0DC)
        _ = mist.Style(Profile.ASCII).foreground(color=color).render(s)

    b.iter[do]()


@parameter
def bench_render_ansi(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.ANSI).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
def bench_render_ansi_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.ANSI.color(0xC9A0DC)
        _ = mist.Style(Profile.ANSI).foreground(color=color).render(s)

    b.iter[do]()


@parameter
def bench_render_ansi256(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.ANSI256).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
def bench_render_ansi256_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.ANSI256.color(0xC9A0DC)
        _ = mist.Style(Profile.ANSI256).foreground(color=color).render(s)

    b.iter[do]()


@parameter
def bench_render_true_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.TRUE_COLOR).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
def bench_render_true_color_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.TRUE_COLOR.color(0xC9A0DC)
        _ = mist.Style(Profile.TRUE_COLOR).foreground(color=color).render(s)

    b.iter[do]()


@parameter
def bench_render_as_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var output = mist.render_as_color("Hello, world!", 0xC9A0DC)
        _ = output

    b.iter[do]()


@parameter
def bench_render_with_background_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var output = mist.render_with_background_color("Hello, world!", 0xC9A0DC)
        _ = output

    b.iter[do]()

# Render many

@parameter
def bench_render_many_ascii(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.ASCII).foreground(0xC9A0DC).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_ascii_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.ASCII.color(0xC9A0DC)
        _ = mist.Style(Profile.ASCII).foreground(color=color).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_ansi(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.ANSI).foreground(0xC9A0DC).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_ansi_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.ANSI.color(0xC9A0DC)
        _ = mist.Style(Profile.ANSI).foreground(color=color).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_ansi256(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.ANSI256).foreground(0xC9A0DC).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_ansi256_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.ANSI256.color(0xC9A0DC)
        _ = mist.Style(Profile.ANSI256).foreground(color=color).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_true_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        _ = mist.Style(Profile.TRUE_COLOR).foreground(0xC9A0DC).render_many("Hello", "World", "!")

    b.iter[do]()


@parameter
def bench_render_many_true_color_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    def do() raises:
        var color = Profile.TRUE_COLOR.color(0xC9A0DC)
        _ = mist.Style(Profile.TRUE_COLOR).foreground(color=color).render_many("Hello", "World", "!")

    b.iter[do]()
