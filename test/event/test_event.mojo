from std import testing
from std.testing import TestSuite
from mist.event.event import (
    Backspace,
    Char,
    FunctionKey,
    KeyCode,
    KeyEvent,
    KeyEventKind,
    KeyEventState,
    KeyModifiers,
    KeyboardEnhancementFlags,
    Left,
    MediaKeyCode,
    ModifierKeyCode,
    MouseButton,
    MouseDrag,
    MouseMoved,
    MousePress,
    MouseRelease,
    MouseScrollDown,
    MouseScrollLeft,
    MouseScrollRight,
    MouseScrollUp,
    Right,
    Up,
)


def test_key_code_equality() raises:
    var up = KeyCode(Up())
    var up2 = KeyCode(Up())
    var left = KeyCode(Left())

    testing.assert_equal(up, up2, msg="KeyCodes with the same type and value should be equal")
    testing.assert_not_equal(up, left, msg="KeyCodes with different types should not be equal")

    var f1 = KeyCode(FunctionKey(1))
    var f12 = KeyCode(FunctionKey(12))
    testing.assert_true(f1.is_same_type(f12), msg="KeyCodes with the same variant type should be considered the same type")
    testing.assert_not_equal(f1, f12, msg="KeyCodes with different values should not be equal")


def test_keyboard_enhancement_flags_equality() raises:
    var a = KeyboardEnhancementFlags(0b0000_0001)
    var b = KeyboardEnhancementFlags(0b0000_0001)
    var c = KeyboardEnhancementFlags(0b0000_0010)
    testing.assert_equal(a, b, msg="Flags with same bits should be equal")
    testing.assert_not_equal(a, c, msg="Flags with different bits should not be equal")


def test_key_modifiers_equality() raises:
    var m1 = KeyModifiers.SHIFT | KeyModifiers.ALT
    var m2 = KeyModifiers.SHIFT | KeyModifiers.ALT
    var m3 = KeyModifiers.CONTROL
    testing.assert_equal(m1, m2, msg="KeyModifiers with same bits should be equal")
    testing.assert_not_equal(m1, m3, msg="KeyModifiers with different bits should not be equal")


def test_key_event_state_equality() raises:
    var s1 = KeyEventState.CAPS_LOCK | KeyEventState.KEYPAD
    var s2 = KeyEventState.CAPS_LOCK | KeyEventState.KEYPAD
    var s3 = KeyEventState.NUM_LOCK
    testing.assert_equal(s1, s2, msg="KeyEventState with same bits should be equal")
    testing.assert_not_equal(s1, s3, msg="KeyEventState with different bits should not be equal")


def test_key_event_kind_equality() raises:
    testing.assert_equal(KeyEventKind.Press, KeyEventKind.Press, msg="Press kind should equal itself")
    testing.assert_not_equal(KeyEventKind.Press, KeyEventKind.Release, msg="Different kinds should not be equal")


def test_media_modifier_key_code_equality() raises:
    var media1 = MediaKeyCode.Play
    var media2 = MediaKeyCode.Play
    var media3 = MediaKeyCode.Pause
    testing.assert_equal(media1, media2, msg="MediaKeyCode with same value should be equal")
    testing.assert_not_equal(media1, media3, msg="MediaKeyCode with different value should not be equal")

    var mod1 = ModifierKeyCode.LeftShift
    var mod2 = ModifierKeyCode.LeftShift
    var mod3 = ModifierKeyCode.RightShift
    testing.assert_equal(mod1, mod2, msg="ModifierKeyCode with same value should be equal")
    testing.assert_not_equal(mod1, mod3, msg="ModifierKeyCode with different value should not be equal")


def test_keycode_is_same_type() raises:
    var backspace = KeyCode(Backspace())
    var up = KeyCode(Up())
    var up2 = KeyCode(Up())
    testing.assert_true(up.is_same_type(up2), msg="Same key variant should be same type")
    testing.assert_false(up.is_same_type(backspace), msg="Different key variants should not be same type")


def test_keycode_char_equality() raises:
    var a1 = KeyCode(Char("a"))
    var a2 = KeyCode(Char("a"))
    var b = KeyCode(Char("b"))
    testing.assert_equal(a1, a2, msg="Char key codes with same char should be equal")
    testing.assert_not_equal(a1, b, msg="Char key codes with different char should not be equal")


def test_key_event_equality_normalized_case() raises:
    var lower = KeyEvent(KeyCode(Char("a")), KeyModifiers.SHIFT)
    var upper = KeyEvent(KeyCode(Char("A")), KeyModifiers.NONE)
    testing.assert_equal(String(lower), String(upper), msg="KeyEvent should normalize case with SHIFT modifier")


def test_mouse_button_equality() raises:
    var left1 = MouseButton.Left
    var left2 = MouseButton.Left
    var right = MouseButton.Right
    testing.assert_equal(left1, left2, msg="MouseButton with same value should be equal")
    testing.assert_not_equal(left1, right, msg="MouseButton with different value should not be equal")


def test_mouse_event_type_equality() raises:
    var press1 = MousePress(MouseButton.Left)
    var press2 = MousePress(MouseButton.Left)
    var press3 = MousePress(MouseButton.Right)
    testing.assert_equal(press1, press2, msg="MousePress with same button should be equal")
    testing.assert_not_equal(press1, press3, msg="MousePress with different buttons should not be equal")

    var release1 = MouseRelease(MouseButton.Left)
    var release2 = MouseRelease(MouseButton.Left)
    testing.assert_equal(release1, release2, msg="MouseRelease with same button should be equal")

    var drag1 = MouseDrag(MouseButton.Left)
    var drag2 = MouseDrag(MouseButton.Left)
    testing.assert_equal(drag1, drag2, msg="MouseDrag with same button should be equal")

    testing.assert_equal(MouseMoved(), MouseMoved(), msg="MouseMoved should be equal")
    testing.assert_equal(MouseScrollDown(), MouseScrollDown(), msg="MouseScrollDown should be equal")
    testing.assert_equal(MouseScrollUp(), MouseScrollUp(), msg="MouseScrollUp should be equal")
    testing.assert_equal(MouseScrollLeft(), MouseScrollLeft(), msg="MouseScrollLeft should be equal")
    testing.assert_equal(MouseScrollRight(), MouseScrollRight(), msg="MouseScrollRight should be equal")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
