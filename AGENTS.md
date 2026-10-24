# AGENTS.md

Notes for coding agents working on mist, a Mojo library for terminal styling.
It ports [termenv](https://github.com/muesli/termenv) (profiles and styling),
[reflow](https://github.com/muesli/reflow) (ANSI-aware text transforms), and
[go-colorful](https://github.com/lucasb-eyer/go-colorful) (color math).

## Commands

All commands run through pixi.

| Task | Command | Notes |
|---|---|---|
| Tests | `pixi run tests` | Runs every `test/test_*.mojo` with `-D ASSERT=all`, so `debug_assert`s are active |
| One test file | `pixi run mojo -D ASSERT=all -I . test/test_color.mojo` | |
| Examples | `pixi run examples` | |
| Docstring lint | `pixi run lint_docs` | `mojo doc --Werror --diagnose-missing-doc-strings`. It also type-checks the whole package |
| Format | `pixi run format` | `mojo format`, line length 120 |
| Benchmarks | `pixi run benchmarks` | |

## Conventions

- Every public symbol needs a docstring with `Args:`, `Parameters:`, `Returns:`
  and `Raises:` sections as they apply. Doc summaries must start with a capital
  letter or a non-letter.
- Don't mark a function `raises` unless something in it can actually raise. The
  linter then requires a `Raises:` section.
- **Known lint limitation (Mojo 1.2.0):** `__enum` cases without a payload
  (`case ASCII`) can't carry a docstring. The `"""..."""` under them is accepted
  but ignored, so `lint_docs` always reports these cases (`Profile.*`,
  `Color.ASCII`). Cases with a payload (`case RGB(UInt32)`) aren't checked.
- `match` on an `__enum` must cover every case. Use `case _:` for the rest.
- `debug_assert(cond, msg)` fails when `cond` is **false**. Write the condition
  that should hold.
- Closures that capture use a capture list after `raises`:
  `def do() raises {imm s}:`. In Mojo 1.2.0 the immutable capture convention
  is `imm` (`read` is rejected). `std.benchmark` takes functions as runtime
  arguments: `b.iter(do)`, `m.bench_with_input(func, BenchId(name), data)`.

## Color code

Before changing anything under `mist/color/`, read
[doc/color-spaces.md](doc/color-spaces.md). It covers the conversion graph, the
divide-by-100 scaling of CIE coordinates, measured sRGB ranges, how HSLuv/HPLuv
work, profile degradation, the range-assertion policy, and where mist
deliberately departs from go-colorful and termenv. In short:

- Lab/Luv/LCh coordinates are the CIE values divided by 100 (L ∈ [0, 1]).
  Scale formulas taken from references to match.
- The reverse path (`from_*`, polar blends) legitimately produces out-of-gamut
  intermediates. Only `Color.from_rgb` clamps (and rounds), so don't add
  gamut-derived bounds to the CIE intermediates' asserts.
- `to_HSLuv` is perceptual HSLuv; `to_hsl` is plain HSL. Don't add another
  zero-argument `to_HSLuv` overload: overload resolution prefers it, which is
  how the two got mixed up before.
- Profile degradation (`hex_to_ansi256`, `ANSI256_TO_ANSI`) uses CIEDE2000,
  not termenv's HSLuv distance, and `hex_to_ansi256` searches 11 candidates.
  `ANSI256_TO_ANSI` and `ANSI256_LAB` in `mist/_ansi_colors.mojo` are generated.
  Regenerate them (the recipes are in their docstrings) if the metric, the Lab
  math or `ANSI_HEX_CODES` changes, and update `test/test_color_spaces.mojo` and
  `test/test_profile.mojo`.
