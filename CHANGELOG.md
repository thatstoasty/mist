# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [0.1.10] - 2024-12-21

- Update profile detection to include a few more terminals.

## [0.1.9] - 2024-12-17

- Remove `gojo` dependencies, any usage of `StringBuilder` now uses String streaming.
- Rendering functions now accept `SizedWritable` types, instead of just `String`.

## [0.1.8] - 2024-09-22

- Pull in null terminator fix from `gojo` library.

## [0.1.7] - 2024-09-21

- Switch to using `StringBuilder.consume()` to avoid copying data.

## [0.1.6] - 2024-09-17

- Pull in compability changes from `hue` library to minimize boilerplate conversion code.

## [0.1.4] - 2024-09-13

- First release with a changelog! Added rattler build and conda publish.
