import benchmark
from benchmark.compiler import keep
import mist
from mist import TerminalStyle, Profile, ASCII, ANSI, ANSI256, TRUE_COLOR
from mist.color import ANSIColor, ANSI256Color, RGBColor


fn bench_rendering_with_profiles():
    var a: String = "Hello World!"
    var profile = Profile()

    var style = mist.new_style().foreground(profile.color("12"))
    var output = style.render(a)

    style = mist.new_style().foreground(profile.color("55"))
    output = style.render(a)

    style = mist.new_style().foreground(profile.color("#c9a0dc"))
    output = style.render(a)

    style = mist.new_style(mist.ASCII_PROFILE).foreground(profile.color("#c9a0dc"))
    output = style.render(a)

    style = mist.new_style(mist.ANSI_PROFILE).foreground(profile.color("#c9a0dc"))
    output = style.render(a)

    style = mist.new_style(mist.ANSI256_PROFILE).foreground(profile.color("#c9a0dc"))
    output = style.render(a)

    style = mist.new_style(mist.TRUE_COLOR_PROFILE).foreground(profile.color("#c9a0dc"))
    output = style.render(a)

    style = mist.new_style(mist.TRUE_COLOR_PROFILE).foreground("#c9a0dc")
    output = style.render(a)
    keep(output)


fn bench_render_as_color():
    var output = mist.render_as_color("Hello, world!", "#c9a0dc")
    keep(output)


fn bench_render_with_background_color():
    var output = mist.render_with_background_color("Hello, world!", "#c9a0dc")
    keep(output)


fn bench_render_big_file():
    var content: String = ""
    try:
        with open("./benchmarks/data/big.txt", "r") as file:
            content = file.read()
            var output = mist.render_as_color(content, "#c9a0dc")
            keep(output)
    except e:
        print(e)


fn main():
    var report = benchmark.run[bench_rendering_with_profiles](max_iters=10)
    report.print(benchmark.Unit.ms)

    report = benchmark.run[bench_render_as_color](max_iters=10)
    report.print(benchmark.Unit.ms)

    report = benchmark.run[bench_render_with_background_color](max_iters=10)
    report.print(benchmark.Unit.ms)

    report = benchmark.run[bench_render_big_file](max_iters=10)
    report.print(benchmark.Unit.ms)
