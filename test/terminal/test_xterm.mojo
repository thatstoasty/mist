from mist.terminal.xterm import XTermColor, parse_xterm_color
from testing import TestSuite, assert_equal


fn test_parse_xterm_color() raises -> None:
    var color_sequence = "rgb:1717/9393/d0d0"
    var expected_color: Tuple[UInt8, UInt8, UInt8] = (23, 147, 208)
    var parsed_color = parse_xterm_color(color_sequence)
    assert_equal(parsed_color[0], expected_color[0], msg="Parsed R color does not match expected color")
    assert_equal(parsed_color[1], expected_color[1], msg="Parsed G color does not match expected color")
    assert_equal(parsed_color[2], expected_color[2], msg="Parsed B color does not match expected color")


fn test_xterm_color_struct() raises -> None:
    var color_sequence = "rgb:1717/9393/d0d0"
    var xterm_color = XTermColor(color_sequence)
    assert_equal(xterm_color.r, 23, msg="Red component does not match expected value")
    assert_equal(xterm_color.g, 147, msg="Green component does not match expected value")
    assert_equal(xterm_color.b, 208, msg="Blue component does not match expected value")


fn test_xterm_color_str() raises -> None:
    var color_sequence = "rgb:1717/9393/d0d0"
    var xterm_color = XTermColor(color_sequence)
    assert_equal(String(xterm_color), color_sequence, msg="String representation of XTermColor does not match original sequence")


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
