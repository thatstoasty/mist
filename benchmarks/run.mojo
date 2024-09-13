import benchmark
import mist
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn bench_rendering_with_profiles():
    alias a: String = "Hello World!"
    var profile = mist.Profile()

    var style = mist.Style().foreground(color=profile.color(12))
    var output = style.render(a)
    output = style.foreground(color=profile.color(55)).render(a)
    output = style.foreground(color=profile.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.ASCII).foreground(color=mist.ASCII_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.ANSI).foreground(color=mist.ANSI_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.ANSI256).foreground(color=mist.ANSI256_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.TRUE_COLOR).foreground(color=mist.TRUE_COLOR_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.TRUE_COLOR).foreground(0xC9A0DC).render(a)
    _ = output


fn bench_comptime_rendering_with_profiles():
    alias a: String = "Hello World!"
    alias profile = mist.TRUE_COLOR_PROFILE
    alias style = mist.Style(profile.value).foreground(color=profile.color(12))
    var output = style.render(a)

    output = style.foreground(color=mist.TRUE_COLOR_PROFILE.color(55)).render(a)
    output = style.foreground(color=mist.TRUE_COLOR_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.ASCII).foreground(color=mist.ASCII_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.ANSI).foreground(color=mist.ANSI_PROFILE.color(0xC9A0DC)).render(a)
    output = mist.Style(mist.ANSI256).foreground(color=mist.ANSI256_PROFILE.color(0xC9A0DC)).render(a)
    output = style.foreground(color=mist.TRUE_COLOR_PROFILE.color(0xC9A0DC)).render(a)
    output = style.foreground(0xC9A0DC).render(a)
    _ = output


fn bench_render_as_color():
    var output = mist.render_as_color("Hello, world!", 0xC9A0DC)
    _ = output


fn bench_render_with_background_color():
    var output = mist.render_with_background_color("Hello, world!", 0xC9A0DC)
    _ = output


fn bench_render_big_file():
    var content: String = ""
    try:
        with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            var output = mist.render_as_color(content, 0xC9A0DC)
            _ = output
    except e:
        print(e)


fn main():
    print("Running bench_rendering_with_profiles")
    var report = benchmark.run[bench_rendering_with_profiles](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running bench_comptime_rendering_with_profiles")
    report = benchmark.run[bench_comptime_rendering_with_profiles](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running bench_render_as_color")
    report = benchmark.run[bench_render_as_color](max_iters=10)
    report.print(benchmark.Unit.ms)

    print("Running bench_render_with_background_color")
    report = benchmark.run[bench_render_with_background_color](max_iters=10)
    report.print(benchmark.Unit.ms)

    print("Running bench_render_big_file")
    report = benchmark.run[bench_render_big_file](max_iters=10)
    report.print(benchmark.Unit.ms)
