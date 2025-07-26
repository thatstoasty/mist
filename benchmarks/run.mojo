import pathlib
import time

import benchmark
from benchmark import Bench, BenchConfig, Bencher, BenchId, BenchMetric, ThroughputMeasure
from mist.color import ANSI256Color, ANSIColor, RGBColor

import mist
from mist import Profile, dedent, indent, margin, padding, truncate, word_wrap, wrap


fn get_gbs_measure(input: String) raises -> ThroughputMeasure:
    return ThroughputMeasure(BenchMetric.bytes, input.byte_length())


fn run[func: fn (mut Bencher, String) raises capturing, name: String](mut m: Bench, data: String) raises:
    m.bench_with_input[String, func](BenchId(name), data, get_gbs_measure(data))


fn run[func: fn (mut Bencher) raises capturing, name: String](mut m: Bench) raises:
    m.bench_function[func](BenchId(name))


@parameter
fn bench_render_ascii(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        _ = mist.Style(Profile.ASCII).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
fn bench_render_ascii_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        var color = Profile.ASCII.color(0xC9A0DC)
        _ = mist.Style(Profile.ASCII).foreground(color=color).render(s)

    b.iter[do]()


@parameter
fn bench_render_ansi(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        _ = mist.Style(Profile.ANSI).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
fn bench_render_ansi_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        var color = Profile.ANSI.color(0xC9A0DC)
        _ = mist.Style(Profile.ANSI).foreground(color=color).render(s)

    b.iter[do]()


@parameter
fn bench_render_ansi256(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        _ = mist.Style(Profile.ANSI256).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
fn bench_render_ansi256_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        var color = Profile.ANSI256.color(0xC9A0DC)
        _ = mist.Style(Profile.ANSI256).foreground(color=color).render(s)

    b.iter[do]()


@parameter
fn bench_render_true_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        _ = mist.Style(Profile.TRUE_COLOR).foreground(0xC9A0DC).render(s)

    b.iter[do]()


@parameter
fn bench_render_true_color_profile_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        alias a = "Hello World!"
        var color = Profile.TRUE_COLOR.color(0xC9A0DC)
        _ = mist.Style(Profile.TRUE_COLOR).foreground(color=color).render(s)

    b.iter[do]()


@parameter
fn bench_render_as_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        var output = mist.render_as_color("Hello, world!", 0xC9A0DC)
        _ = output

    b.iter[do]()


@parameter
fn bench_render_with_background_color(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        var output = mist.render_with_background_color("Hello, world!", 0xC9A0DC)
        _ = output

    b.iter[do]()


@parameter
fn bench_indent(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = indent(s, 4)

    b.iter[do]()


@parameter
fn bench_dedent(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = dedent(s)

    b.iter[do]()


@parameter
fn bench_margin(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = margin(s, 4, 4)

    b.iter[do]()


@parameter
fn bench_word_wrap(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = word_wrap(s, 100)

    b.iter[do]()


@parameter
fn bench_wrap(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = wrap(s, 100)

    b.iter[do]()


@parameter
fn bench_truncate(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = truncate(s, 100)

    b.iter[do]()


@parameter
fn bench_padding(mut b: Bencher, s: String) raises:
    @always_inline
    @parameter
    fn do() raises:
        _ = padding(s, 4)

    b.iter[do]()


# fn bench_render_big_file():
#     var content: String = ""
#     try:
#         with open("./benchmarks/data/big.txt", "r") as file:
#             content = file.read()
#             var output = mist.render_as_color(content, 0xC9A0DC)
#             _ = output
#     except e:
#         print(e)


def main():
    var config = BenchConfig()
    config.verbose_timing = True
    config.flush_denormals = True
    config.show_progress = True
    var bench_config = Bench(config)

    alias text = "Hello World!"
    run[bench_render_ascii, "bench_render_ascii"](bench_config, text)
    run[bench_render_ascii_profile_color, "bench_render_ascii_profile_color"](bench_config, text)
    run[bench_render_ansi, "bench_render_ansi"](bench_config, text)
    run[bench_render_ansi_profile_color, "bench_render_ansi_profile_color"](bench_config, text)
    run[bench_render_ansi256, "bench_render_ansi256"](bench_config, text)
    run[bench_render_ansi256_profile_color, "bench_render_ansi256_profile_color"](bench_config, text)
    run[bench_render_true_color, "bench_render_true_color"](bench_config, text)
    run[bench_render_true_color_profile_color, "bench_render_true_color_profile_color"](bench_config, text)
    run[bench_render_as_color, "bench_render_as_color"](bench_config, text)
    run[bench_render_with_background_color, "bench_render_with_background_color"](bench_config, text)

    # print("Running bench_render_big_file")
    # report = benchmark.run[bench_render_big_file](max_iters=10)
    # report.print(benchmark.Unit.ms)

    var path = String(pathlib._dir_of_current_file()) + "/data/big.txt"
    var data: String
    with open(path, "r") as file:
        data = file.read()

    run[bench_indent, "Indent"](bench_config, data)
    run[bench_dedent, "Dedent"](bench_config, data)
    run[bench_margin, "Margin"](bench_config, data)
    run[bench_word_wrap, "WordWrap"](bench_config, data)
    run[bench_wrap, "Wrap"](bench_config, data)
    run[bench_truncate, "Truncate"](bench_config, data)
    run[bench_padding, "Padding"](bench_config, data)

    bench_config.dump_report()
