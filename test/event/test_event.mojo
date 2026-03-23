from std import testing
from std.testing import TestSuite
from mist.event.event import KeyCode, Up, Left, Right, FunctionKey


fn test_key_code_equality() raises:
    var up = KeyCode(Up())
    var up2 = KeyCode(Up())
    var left = KeyCode(Left())

    testing.assert_equal(up, up2, msg="KeyCodes with the same type and value should be equal")
    testing.assert_not_equal(up, left, msg="KeyCodes with different types should not be equal")

    var f1 = KeyCode(FunctionKey(1))
    var f12 = KeyCode(FunctionKey(12))
    testing.assert_true(f1.is_same_type(f12), msg="KeyCodes with the same variant type should be considered the same type")
    testing.assert_not_equal(f1, f12, msg="KeyCodes with different values should not be equal")


fn main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
