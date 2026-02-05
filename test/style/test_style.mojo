import testing
from mist.style.profile import Profile
from testing import TestSuite

import mist
from mist.style.style import SGR


fn test_bold() raises:
    testing.assert_equal(
        mist.Style(Profile.ANSI).bold().render("Hello─World"), "\x1B[" + SGR.BOLD + "mHello─World\x1B[0m"
    )


fn test_faint() raises:
    testing.assert_equal(
        mist.Style(Profile.ANSI).faint().render("Hello─World"), "\x1B[" + SGR.FAINT + "mHello─World\x1B[0m"
    )


fn test_italic() raises:
    testing.assert_equal(
        mist.Style(Profile.ANSI).italic().render("Hello─World"), "\x1B[" + SGR.ITALIC + "mHello─World\x1B[0m"
    )


fn test_underline() raises:
    testing.assert_equal(mist.Style(Profile.ANSI).underline().render("Hello─World"), "\x1B[4mHello─World\x1B[0m")


fn test_blink() raises:
    testing.assert_equal(mist.Style(Profile.ANSI).blink().render("Hello─World"), "\x1B[5mHello─World\x1B[0m")


fn test_reverse() raises:
    testing.assert_equal(mist.Style(Profile.ANSI).reverse().render("Hello─World"), "\x1B[7mHello─World\x1B[0m")


fn test_crossout() raises:
    testing.assert_equal(mist.Style(Profile.ANSI).strikethrough().render("Hello─World"), "\x1B[9mHello─World\x1B[0m")


fn test_bold_faint() raises:
    testing.assert_equal(mist.Style(Profile.ANSI).bold().faint().render("Hello─World"), "\x1B[1;2mHello─World\x1B[0m")


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
