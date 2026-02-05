"""Parser module for terminal input handling.

This module provides functionality to parse terminal input byte sequences into
structured events. It handles escape sequences, control characters, mouse events,
keyboard events, and more.

The parser converts raw terminal input bytes into InternalEvent structures that
can contain:
- Regular events (key, mouse, focus, paste, resize)
- Cursor position responses
- Keyboard enhancement flag responses
- Primary device attribute responses

## Parsing Strategy

The parsing follows these conventions:
- `None` return -> wait for more bytes
- Error raise -> failed to parse event, clear the buffer
- `Some(event)` return -> we have event, clear the buffer
"""

from sys import stdin

from mist.event.internal import CursorPosition, InternalEvent, KeyboardEnhancementFlagsResponse, PrimaryDeviceAttributes
from mist.terminal.sgr import CSI, ESC
from mist.termios.tty import is_terminal_raw
from utils import Variant

from mist.event.event import (  # Key types; Mouse event types; Event types
    Backspace,
    BackTab,
    CapsLock,
    Char,
    Delete,
    Down,
    End,
    Enter,
    Esc,
    Event,
    FocusGained,
    FocusLost,
    FunctionKey,
    Home,
    Insert,
    InternalEventType,
    KeyboardEnhancementFlags,
    KeyCode,
    KeyEvent,
    KeyEventKind,
    KeyEventState,
    KeyModifiers,
    KeypadBegin,
    Left,
    MediaKeyCode,
    Menu,
    ModifierKeyCode,
    MouseButton,
    MouseDrag,
    MouseEvent,
    MouseEventKind,
    MouseMoved,
    MousePress,
    MouseRelease,
    MouseScrollDown,
    MouseScrollLeft,
    MouseScrollRight,
    MouseScrollUp,
    Null,
    NumLock,
    PageDown,
    PageUp,
    Paste,
    Pause,
    PrintScreen,
    Resize,
    Right,
    ScrollLock,
    Tab,
    Up,
)


fn starts_with[pattern: StringSlice](buffer: Span[UInt8]) -> Bool:
    for expected, actual in zip(pattern.as_bytes(), buffer):
        if expected != actual:
            return False
    return True


fn assert_starts_with[pattern: StringSlice](buffer: Span[UInt8]) raises:
    """Assert that the buffer starts with the CSI sequence."""
    # TODO: Test which is faster - converting pattern to bytes at comptime or comparing as string slices
    # if not StringSlice(from_utf8=buffer).startswith(pattern):
    #     raise Error("Buffer does not start with expected pattern: ", pattern)

    if not starts_with[pattern](buffer):
        raise Error("Buffer does not start with expected pattern: ", pattern)


fn ends_with[pattern: StringSlice](buffer: Span[UInt8]) -> Bool:
    for expected, actual in zip(reversed(pattern.as_bytes()), reversed(buffer)):
        if expected != actual:
            return False
    return True


fn assert_ends_with[pattern: StringSlice](buffer: Span[UInt8]) raises:
    """Assert that the buffer ends with the CSI sequence."""
    if not ends_with[pattern](buffer):
        raise Error("Buffer does not start with expected pattern: ", pattern)


# ============================================================================
# Error Handling
# ============================================================================


fn could_not_parse_event_error() -> Error:
    """Create a parse error for failed event parsing."""
    return Error("Could not parse an event")


# ============================================================================
# Helper Functions
# ============================================================================


fn _saturating_sub(value: UInt8, sub: UInt8) -> UInt8:
    """Subtract sub from value, saturating at 0."""
    if value > sub:
        return value - sub
    return 0


fn _char_to_digit(c: UInt8) -> Optional[UInt8]:
    """Convert an ASCII digit character to its numeric value."""
    if c >= ord("0") and c <= ord("9"):
        return c - ord("0")
    return None


# ============================================================================
# Modifier Parsing
# ============================================================================


fn parse_modifiers(mask: UInt8) -> KeyModifiers:
    """Parse key modifiers from a modifier mask.

    Args:
        mask: The modifier mask byte.

    Returns:
        The parsed KeyModifiers.
    """
    var modifier_mask = _saturating_sub(mask, 1)
    var modifiers = KeyModifiers.NONE

    if modifier_mask & 1 != 0:
        modifiers = modifiers | KeyModifiers.SHIFT
    if modifier_mask & 2 != 0:
        modifiers = modifiers | KeyModifiers.ALT
    if modifier_mask & 4 != 0:
        modifiers = modifiers | KeyModifiers.CONTROL
    if modifier_mask & 8 != 0:
        modifiers = modifiers | KeyModifiers.SUPER
    if modifier_mask & 16 != 0:
        modifiers = modifiers | KeyModifiers.HYPER
    if modifier_mask & 32 != 0:
        modifiers = modifiers | KeyModifiers.META

    return modifiers


fn parse_modifiers_to_state(mask: UInt8) -> KeyEventState:
    """Parse key event state from a modifier mask.

    Args:
        mask: The modifier mask byte.

    Returns:
        The parsed KeyEventState.
    """
    var modifier_mask = _saturating_sub(mask, 1)
    var state = KeyEventState.NONE

    if modifier_mask & 64 != 0:
        state = state | KeyEventState.CAPS_LOCK
    if modifier_mask & 128 != 0:
        state = state | KeyEventState.NUM_LOCK

    return state


fn parse_key_event_kind(kind: UInt8) -> KeyEventKind:
    """Parse key event kind from a kind code.

    Args:
        kind: The kind code byte.

    Returns:
        The parsed KeyEventKind.
    """
    if kind == 1:
        return KeyEventKind.Press
    elif kind == 2:
        return KeyEventKind.Repeat
    elif kind == 3:
        return KeyEventKind.Release
    else:
        return KeyEventKind.Press


# ============================================================================
# Functional Key Code Translation
# ============================================================================


fn translate_functional_key_code(codepoint: UInt32) -> Optional[Tuple[KeyCode, KeyEventState]]:
    """Translate a functional key codepoint to a KeyCode and state.

    These are special codepoints defined in the Kitty Keyboard Protocol.
    """
    # Keypad keys (return with KEYPAD state)
    if codepoint == 57399:
        return (KeyCode(Char("0")), KeyEventState.KEYPAD)
    elif codepoint == 57400:
        return (KeyCode(Char("1")), KeyEventState.KEYPAD)
    elif codepoint == 57401:
        return (KeyCode(Char("2")), KeyEventState.KEYPAD)
    elif codepoint == 57402:
        return (KeyCode(Char("3")), KeyEventState.KEYPAD)
    elif codepoint == 57403:
        return (KeyCode(Char("4")), KeyEventState.KEYPAD)
    elif codepoint == 57404:
        return (KeyCode(Char("5")), KeyEventState.KEYPAD)
    elif codepoint == 57405:
        return (KeyCode(Char("6")), KeyEventState.KEYPAD)
    elif codepoint == 57406:
        return (KeyCode(Char("7")), KeyEventState.KEYPAD)
    elif codepoint == 57407:
        return (KeyCode(Char("8")), KeyEventState.KEYPAD)
    elif codepoint == 57408:
        return (KeyCode(Char("9")), KeyEventState.KEYPAD)
    elif codepoint == 57409:
        return (KeyCode(Char(".")), KeyEventState.KEYPAD)
    elif codepoint == 57410:
        return (KeyCode(Char("/")), KeyEventState.KEYPAD)
    elif codepoint == 57411:
        return (KeyCode(Char("*")), KeyEventState.KEYPAD)
    elif codepoint == 57412:
        return (KeyCode(Char("-")), KeyEventState.KEYPAD)
    elif codepoint == 57413:
        return (KeyCode(Char("+")), KeyEventState.KEYPAD)
    elif codepoint == 57414:
        return (KeyCode(Enter()), KeyEventState.KEYPAD)
    elif codepoint == 57415:
        return (KeyCode(Char("=")), KeyEventState.KEYPAD)
    elif codepoint == 57416:
        return (KeyCode(Char(",")), KeyEventState.KEYPAD)
    elif codepoint == 57417:
        return (KeyCode(Left()), KeyEventState.KEYPAD)
    elif codepoint == 57418:
        return (KeyCode(Right()), KeyEventState.KEYPAD)
    elif codepoint == 57419:
        return (KeyCode(Up()), KeyEventState.KEYPAD)
    elif codepoint == 57420:
        return (KeyCode(Down()), KeyEventState.KEYPAD)
    elif codepoint == 57421:
        return (KeyCode(PageUp()), KeyEventState.KEYPAD)
    elif codepoint == 57422:
        return (KeyCode(PageDown()), KeyEventState.KEYPAD)
    elif codepoint == 57423:
        return (KeyCode(Home()), KeyEventState.KEYPAD)
    elif codepoint == 57424:
        return (KeyCode(End()), KeyEventState.KEYPAD)
    elif codepoint == 57425:
        return (KeyCode(Insert()), KeyEventState.KEYPAD)
    elif codepoint == 57426:
        return (KeyCode(Delete()), KeyEventState.KEYPAD)
    elif codepoint == 57427:
        return (KeyCode(KeypadBegin()), KeyEventState.KEYPAD)

    # Lock and function keys (return with empty state)
    elif codepoint == 57358:
        return (KeyCode(CapsLock()), KeyEventState.NONE)
    elif codepoint == 57359:
        return (KeyCode(ScrollLock()), KeyEventState.NONE)
    elif codepoint == 57360:
        return (KeyCode(NumLock()), KeyEventState.NONE)
    elif codepoint == 57361:
        return (KeyCode(PrintScreen()), KeyEventState.NONE)
    elif codepoint == 57362:
        return (KeyCode(Pause()), KeyEventState.NONE)
    elif codepoint == 57363:
        return (KeyCode(Menu()), KeyEventState.NONE)
    elif codepoint >= 57376 and codepoint <= 57398:
        # F13-F35
        var fn_num = UInt8(codepoint - 57376 + 13)
        return (KeyCode(FunctionKey(fn_num)), KeyEventState.NONE)

    # Media keys
    elif codepoint == 57428:
        return (KeyCode(MediaKeyCode.Play), KeyEventState.NONE)
    elif codepoint == 57429:
        return (KeyCode(MediaKeyCode.Pause), KeyEventState.NONE)
    elif codepoint == 57430:
        return (KeyCode(MediaKeyCode.PlayPause), KeyEventState.NONE)
    elif codepoint == 57431:
        return (KeyCode(MediaKeyCode.Reverse), KeyEventState.NONE)
    elif codepoint == 57432:
        return (KeyCode(MediaKeyCode.Stop), KeyEventState.NONE)
    elif codepoint == 57433:
        return (KeyCode(MediaKeyCode.FastForward), KeyEventState.NONE)
    elif codepoint == 57434:
        return (KeyCode(MediaKeyCode.Rewind), KeyEventState.NONE)
    elif codepoint == 57435:
        return (KeyCode(MediaKeyCode.TrackNext), KeyEventState.NONE)
    elif codepoint == 57436:
        return (KeyCode(MediaKeyCode.TrackPrevious), KeyEventState.NONE)
    elif codepoint == 57437:
        return (KeyCode(MediaKeyCode.Record), KeyEventState.NONE)
    elif codepoint == 57438:
        return (KeyCode(MediaKeyCode.LowerVolume), KeyEventState.NONE)
    elif codepoint == 57439:
        return (KeyCode(MediaKeyCode.RaiseVolume), KeyEventState.NONE)
    elif codepoint == 57440:
        return (KeyCode(MediaKeyCode.MuteVolume), KeyEventState.NONE)

    # Modifier keys
    elif codepoint == 57441:
        return (KeyCode(ModifierKeyCode.LeftShift), KeyEventState.NONE)
    elif codepoint == 57442:
        return (KeyCode(ModifierKeyCode.LeftControl), KeyEventState.NONE)
    elif codepoint == 57443:
        return (KeyCode(ModifierKeyCode.LeftAlt), KeyEventState.NONE)
    elif codepoint == 57444:
        return (KeyCode(ModifierKeyCode.LeftSuper), KeyEventState.NONE)
    elif codepoint == 57445:
        return (KeyCode(ModifierKeyCode.LeftHyper), KeyEventState.NONE)
    elif codepoint == 57446:
        return (KeyCode(ModifierKeyCode.LeftMeta), KeyEventState.NONE)
    elif codepoint == 57447:
        return (KeyCode(ModifierKeyCode.RightShift), KeyEventState.NONE)
    elif codepoint == 57448:
        return (KeyCode(ModifierKeyCode.RightControl), KeyEventState.NONE)
    elif codepoint == 57449:
        return (KeyCode(ModifierKeyCode.RightAlt), KeyEventState.NONE)
    elif codepoint == 57450:
        return (KeyCode(ModifierKeyCode.RightSuper), KeyEventState.NONE)
    elif codepoint == 57451:
        return (KeyCode(ModifierKeyCode.RightHyper), KeyEventState.NONE)
    elif codepoint == 57452:
        return (KeyCode(ModifierKeyCode.RightMeta), KeyEventState.NONE)
    elif codepoint == 57453:
        return (KeyCode(ModifierKeyCode.IsoLevel3Shift), KeyEventState.NONE)
    elif codepoint == 57454:
        return (KeyCode(ModifierKeyCode.IsoLevel5Shift), KeyEventState.NONE)

    return None


# ============================================================================
# Mouse Event Parsing
# ============================================================================


fn parse_cb(cb: UInt8) raises -> Tuple[MouseEventKind, KeyModifiers]:
    """Parse the mouse button/modifier byte.

    Cb is the byte of a mouse input that contains the button being used,
    the key modifiers being held and whether the mouse is dragging or not.

    Bit layout of cb, from low to high:
    - button number (bits 0-1)
    - shift (bit 2)
    - meta/alt (bit 3)
    - control (bit 4)
    - mouse is dragging (bit 5)
    - button number high bits (bits 6-7)

    Args:
        cb: The control byte.

    Returns:
        Tuple of (MouseEventKind, KeyModifiers).

    Raises:
        ParseError for unsupported button combinations.
    """
    var button_number = (cb & 0b0000_0011) | ((cb & 0b1100_0000) >> 4)
    var dragging = (cb & 0b0010_0000) == 0b0010_0000

    var kind: MouseEventKind

    if button_number == 0 and not dragging:
        kind = MousePress(MouseButton.Left)
    elif button_number == 1 and not dragging:
        kind = MousePress(MouseButton.Middle)
    elif button_number == 2 and not dragging:
        kind = MousePress(MouseButton.Right)
    elif button_number == 0 and dragging:
        kind = MouseDrag(MouseButton.Left)
    elif button_number == 1 and dragging:
        kind = MouseDrag(MouseButton.Middle)
    elif button_number == 2 and dragging:
        kind = MouseDrag(MouseButton.Right)
    elif button_number == 3 and not dragging:
        kind = MouseRelease(MouseButton.Left)
    elif (button_number == 3 or button_number == 4 or button_number == 5) and dragging:
        kind = MouseMoved()
    elif button_number == 4 and not dragging:
        kind = MouseScrollUp()
    elif button_number == 5 and not dragging:
        kind = MouseScrollDown()
    elif button_number == 6 and not dragging:
        kind = MouseScrollLeft()
    elif button_number == 7 and not dragging:
        kind = MouseScrollRight()
    else:
        raise could_not_parse_event_error()

    var modifiers = KeyModifiers.NONE
    if cb & 0b0000_0100 == 0b0000_0100:
        modifiers = modifiers | KeyModifiers.SHIFT
    if cb & 0b0000_1000 == 0b0000_1000:
        modifiers = modifiers | KeyModifiers.ALT
    if cb & 0b0001_0000 == 0b0001_0000:
        modifiers = modifiers | KeyModifiers.CONTROL

    return (kind, modifiers)


fn parse_csi_rxvt_mouse(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse rxvt mouse encoding.

    Format: ESC [ Cb ; Cx ; Cy ; M

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the mouse event.
    """
    # Buffer should start with ESC [ and end with M
    assert_starts_with[CSI](buffer)
    assert_ends_with["M"](buffer)

    # Parse the parameters between ESC[ and M
    var s = StringSlice(from_utf8=buffer[2 : len(buffer) - 1])
    var parts = s.split(";")

    if len(parts) < 3:
        raise could_not_parse_event_error()

    var cb_raw = UInt8(atol(parts[0]))
    if cb_raw < 32:
        raise could_not_parse_event_error()
    var cb = cb_raw - 32

    var kind_and_mods = parse_cb(cb)
    var kind = kind_and_mods[0]
    var modifiers = kind_and_mods[1]

    var cx = UInt16(atol(parts[1])) - 1
    var cy = UInt16(atol(parts[2])) - 1

    return InternalEvent(Event(MouseEvent(kind, cx, cy, modifiers)))


fn parse_csi_normal_mouse(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse normal mouse encoding.

    Format: ESC [ M CB Cx Cy (6 characters only)

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the mouse event.
    """
    # Buffer should start with ESC [ M
    assert_starts_with[CSI + "M"](buffer)
    if len(buffer) < 6:
        return None

    if buffer[3] < 32:
        raise could_not_parse_event_error()
    var cb = buffer[3] - 32

    var kind, modifiers = parse_cb(cb)

    # The upper left character position on the terminal is denoted as 1,1.
    # Subtract 1 to keep it synced with cursor
    var cx: UInt16 = 0
    var cy: UInt16 = 0

    if buffer[4] >= 32:
        cx = UInt16(buffer[4] - 32)
        if cx > 0:
            cx -= 1

    if buffer[5] >= 32:
        cy = UInt16(buffer[5] - 32)
        if cy > 0:
            cy -= 1

    return InternalEvent(Event(MouseEvent(kind, cx, cy, modifiers)))


fn parse_csi_sgr_mouse(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse SGR mouse encoding.

    Format: ESC [ < Cb ; Cx ; Cy (;) (M or m)

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the mouse event.
    """
    # Buffer should start with ESC [ <
    assert_starts_with[CSI + "<"](buffer)
    var last_byte = buffer[len(buffer)]
    if last_byte != ord("m") and last_byte != ord("M"):
        return None

    # Parse the parameters between ESC[< and M/m
    var s = StringSlice(from_utf8=buffer[3 : len(buffer) - 1])
    var parts = s.split(";")

    if len(parts) < 3:
        raise could_not_parse_event_error()

    var cb = UInt8(atol(parts[0]))
    var kind, modifiers = parse_cb(cb)

    # The upper left character position on the terminal is denoted as 1,1.
    # Subtract 1 to keep it synced with cursor
    var cx = UInt16(atol(parts[1])) - 1
    var cy = UInt16(atol(parts[2])) - 1

    # When button 3 in Cb is used to represent mouse release, you can't tell
    # which button was released. SGR mode solves this by having the sequence
    # end with a lowercase m if it's a button release and an uppercase M if
    # it's a button press.
    if last_byte == m_BYTE:
        # Convert Down to Up for release
        if kind.isa[MousePress]():
            var button = kind[MousePress].button
            kind = MouseRelease(button)

    return InternalEvent(Event(MouseEvent(kind, cx, cy, modifiers)))


# ============================================================================
# Cursor Position Parsing
# ============================================================================


fn parse_csi_cursor_position(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse cursor position response.

    Format: ESC [ Cy ; Cx R
      Cy - cursor row number (starting from 1)
      Cx - cursor column number (starting from 1)

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the cursor position.
    """
    # Buffer should start with CSI (ESC [) and end with R
    assert_starts_with[CSI](buffer)
    assert_ends_with["R"](buffer)

    # Parse the parameters between ESC[ and R
    var s = StringSlice(from_utf8=buffer[2 : len(buffer) - 1])
    var parts = s.split(";")

    if len(parts) < 2:
        raise could_not_parse_event_error()

    var y = UInt16(atol(parts[0])) - 1
    var x = UInt16(atol(parts[1])) - 1

    return InternalEvent(CursorPosition(x, y))


# ============================================================================
# Keyboard Enhancement Flags Parsing
# ============================================================================


fn parse_csi_keyboard_enhancement_flags(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse keyboard enhancement flags response.

    Format: ESC [ ? flags u

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the keyboard enhancement flags.
    """
    # Buffer should start with ESC [ ? and end with u
    assert_starts_with[CSI + "?"](buffer)
    assert_ends_with["u"](buffer)
    if len(buffer) < 5:
        return None

    var bits = buffer[3]
    var flags = KeyboardEnhancementFlags(0)

    if bits & 1 != 0:
        flags.insert(KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES)
    if bits & 2 != 0:
        flags.insert(KeyboardEnhancementFlags.REPORT_EVENT_TYPES)
    if bits & 4 != 0:
        flags.insert(KeyboardEnhancementFlags.REPORT_ALTERNATE_KEYS)
    if bits & 8 != 0:
        flags.insert(KeyboardEnhancementFlags.REPORT_ALL_KEYS_AS_ESCAPE_CODES)

    return InternalEvent(KeyboardEnhancementFlagsResponse(flags))


# ============================================================================
# Primary Device Attributes Parsing
# ============================================================================


fn parse_csi_primary_device_attributes(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse primary device attributes response.

    Format: ESC [ 64 ; attr1 ; attr2 ; ... ; attrn ; c

    This is a stub - the response is not exposed in the public API.

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing primary device attributes.
    """
    # Buffer should start with ESC [ ? and end with c
    assert_starts_with[CSI + "?"](buffer)
    assert_ends_with["c"](buffer)
    return InternalEvent(PrimaryDeviceAttributes())


# ============================================================================
# Modifier Key Code Parsing
# ============================================================================


fn parse_csi_modifier_key_code(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse CSI modifier key code sequence.

    Args:
        buffer: The input buffer starting with ESC [.

    Returns:
        Optional InternalEvent containing the key event.
    """
    # Parse the string portion between ESC[ and the final byte
    assert_starts_with[CSI](buffer)
    var s = StringSlice(from_utf8=buffer[2 : len(buffer) - 1])
    var parts = s.split(";")

    var modifiers = KeyModifiers.NONE
    var kind = KeyEventKind.Press

    if len(parts) > 1:
        # Try to parse modifier:kind format
        var mod_parts = parts[1].split(":")
        if len(mod_parts) >= 1 and len(mod_parts[0]) > 0:
            var modifier_mask = UInt8(atol(mod_parts[0]))
            modifiers = parse_modifiers(modifier_mask)
            if len(mod_parts) >= 2:
                var kind_code = UInt8(atol(mod_parts[1]))
                kind = parse_key_event_kind(kind_code)
    elif len(buffer) > 3:
        # Try to parse single digit modifier
        if Codepoint(buffer[len(buffer) - 2]).is_ascii_digit():
            modifiers = parse_modifiers(_char_to_digit(buffer[len(buffer) - 2]).value())
        else:
            raise could_not_parse_event_error()
        # var maybe_digit = _char_to_digit(buffer[len(buffer) - 2])
        # if maybe_digit:
        #     modifiers = parse_modifiers(maybe_digit.value())

    var key = buffer[len(buffer) - 1]

    var keycode: KeyCode
    if key == ord("A"):
        keycode = KeyCode(Up())
    elif key == ord("B"):
        keycode = KeyCode(Down())
    elif key == ord("C"):
        keycode = KeyCode(Right())
    elif key == ord("D"):
        keycode = KeyCode(Left())
    elif key == ord("F"):
        keycode = KeyCode(End())
    elif key == ord("H"):
        keycode = KeyCode(Home())
    elif key == ord("P"):
        keycode = KeyCode(FunctionKey(1))
    elif key == ord("Q"):
        keycode = KeyCode(FunctionKey(2))
    elif key == ord("R"):
        keycode = KeyCode(FunctionKey(3))
    elif key == ord("S"):
        keycode = KeyCode(FunctionKey(4))
    else:
        raise could_not_parse_event_error()

    return InternalEvent(Event(KeyEvent(keycode, modifiers, kind)))


# ============================================================================
# Special Key Code Parsing
# ============================================================================


fn parse_csi_special_key_code(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse CSI special key code sequence.

    Format: ESC [ number ; modifier ~

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the key event.
    """
    # Parse the string portion between ESC[ and ~
    assert_starts_with[CSI](buffer)
    assert_ends_with["~"](buffer)

    var s = StringSlice(from_utf8=buffer[2 : len(buffer) - 1])
    var parts = s.split(";")

    if len(parts) < 1 or len(parts[0]) == 0:
        raise could_not_parse_event_error()

    var first = UInt8(atol(parts[0]))

    var modifiers = KeyModifiers.NONE
    var kind = KeyEventKind.Press
    var state = KeyEventState.NONE

    if len(parts) > 1:
        # Try to parse modifier:kind format
        var mod_parts = String(parts[1]).split(":")
        if len(mod_parts) >= 1 and len(mod_parts[0]) > 0:
            var modifier_mask = UInt8(atol(mod_parts[0]))
            modifiers = parse_modifiers(modifier_mask)
            state = parse_modifiers_to_state(modifier_mask)
            if len(mod_parts) >= 2:
                var kind_code = UInt8(atol(mod_parts[1]))
                kind = parse_key_event_kind(kind_code)

    var keycode: KeyCode
    if first == 1 or first == 7:
        keycode = KeyCode(Home())
    elif first == 2:
        keycode = KeyCode(Insert())
    elif first == 3:
        keycode = KeyCode(Delete())
    elif first == 4 or first == 8:
        keycode = KeyCode(End())
    elif first == 5:
        keycode = KeyCode(PageUp())
    elif first == 6:
        keycode = KeyCode(PageDown())
    elif first >= 11 and first <= 15:
        keycode = KeyCode(FunctionKey(first - 10))
    elif first >= 17 and first <= 21:
        keycode = KeyCode(FunctionKey(first - 11))
    elif first >= 23 and first <= 26:
        keycode = KeyCode(FunctionKey(first - 12))
    elif first >= 28 and first <= 29:
        keycode = KeyCode(FunctionKey(first - 15))
    elif first >= 31 and first <= 34:
        keycode = KeyCode(FunctionKey(first - 17))
    else:
        raise could_not_parse_event_error()

    var key_event = KeyEvent(keycode, modifiers, kind, state)
    return InternalEvent(Event(key_event))


# ============================================================================
# CSI U Encoded Key Code Parsing
# ============================================================================


fn parse_csi_u_encoded_key_code(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse CSI u encoded key code (Kitty keyboard protocol).

    Format: CSI codepoint ; modifiers u (basic)
            CSI unicode-key-code:alternate-key-codes ; modifiers:event-type ; text-as-codepoints u (full)

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the key event.
    """
    # Parse the string portion between ESC[ and u
    assert_starts_with[CSI](buffer)
    assert_ends_with["u"](buffer)

    var s = StringSlice(from_utf8=buffer[2 : len(buffer) - 1])
    var parts = s.split(";")

    if len(parts) < 1:
        raise could_not_parse_event_error()

    # Parse the codepoint(s) - can be multiple separated by :
    var codepoint_parts = String(parts[0]).split(":")
    if len(codepoint_parts) < 1 or len(codepoint_parts[0]) == 0:
        raise could_not_parse_event_error()

    var codepoint = UInt32(atol(codepoint_parts[0]))

    # Parse modifiers and kind
    var modifiers = KeyModifiers.NONE
    var kind = KeyEventKind.Press
    var state_from_modifiers = KeyEventState.NONE

    if len(parts) > 1:
        var mod_parts = String(parts[1]).split(":")
        if len(mod_parts) >= 1 and len(mod_parts[0]) > 0:
            var modifier_mask = UInt8(atol(mod_parts[0]))
            modifiers = parse_modifiers(modifier_mask)
            state_from_modifiers = parse_modifiers_to_state(modifier_mask)
            if len(mod_parts) >= 2:
                var kind_code = UInt8(atol(mod_parts[1]))
                kind = parse_key_event_kind(kind_code)

    # Translate the codepoint to a keycode
    var keycode: KeyCode
    var state_from_keycode = KeyEventState.NONE

    var functional = translate_functional_key_code(codepoint)
    if functional:
        keycode = functional.value()[0].copy()
        state_from_keycode = functional.value()[1]
    else:
        # Try to convert codepoint to character
        if codepoint == 0x1B:
            keycode = Esc()
        # TODO: Why does Enter come through as captial J?
        elif codepoint == 0x0D or codepoint == 0x0A:  # \r or \n
            keycode = Enter()
        elif codepoint == 0x09:  # \t
            if modifiers.contains(KeyModifiers.SHIFT):
                keycode = BackTab()
            else:
                keycode = Tab()
        elif codepoint == 0x7F:
            keycode = Backspace()
        elif codepoint <= 0x10FFFF:
            # Valid Unicode codepoint
            keycode = Char(codepoint)
        else:
            raise could_not_parse_event_error()

    # Handle modifier key press adding the modifier
    if keycode.isa[ModifierKeyCode]():
        var mod_code = keycode[ModifierKeyCode]
        if mod_code == ModifierKeyCode.LeftAlt or mod_code == ModifierKeyCode.RightAlt:
            modifiers.insert(KeyModifiers.ALT)
        elif mod_code == ModifierKeyCode.LeftControl or mod_code == ModifierKeyCode.RightControl:
            modifiers.insert(KeyModifiers.CONTROL)
        elif mod_code == ModifierKeyCode.LeftShift or mod_code == ModifierKeyCode.RightShift:
            modifiers.insert(KeyModifiers.SHIFT)
        elif mod_code == ModifierKeyCode.LeftSuper or mod_code == ModifierKeyCode.RightSuper:
            modifiers.insert(KeyModifiers.SUPER)
        elif mod_code == ModifierKeyCode.LeftHyper or mod_code == ModifierKeyCode.RightHyper:
            modifiers.insert(KeyModifiers.HYPER)
        elif mod_code == ModifierKeyCode.LeftMeta or mod_code == ModifierKeyCode.RightMeta:
            modifiers.insert(KeyModifiers.META)

    # Handle shifted alternate keycode
    if modifiers.contains(KeyModifiers.SHIFT) and len(codepoint_parts) > 1:
        var shifted_codepoint = UInt32(atol(codepoint_parts[1]))
        if shifted_codepoint <= 0x10FFFF:
            keycode = Char(shifted_codepoint)
            modifiers.remove(KeyModifiers.SHIFT)

    var final_state = state_from_keycode | state_from_modifiers
    var key_event = KeyEvent(keycode, modifiers, kind, final_state)
    return InternalEvent(Event(key_event))


# ============================================================================
# Bracketed Paste Parsing
# ============================================================================


fn parse_csi_bracketed_paste(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse bracketed paste sequence.

    Format: ESC [ 2 0 0 ~ pasted text ESC [ 2 0 1 ~

    Args:
        buffer: The input buffer.

    Returns:
        Optional InternalEvent containing the paste event.
    """
    # Check if we have the end sequence
    # ESC [ 2 0 1 ~ = \x1b[201~
    assert_starts_with[CSI + "200~"](buffer)
    if not ends_with["201~"](buffer):
        return None

    # Extract the pasted content
    # The pasted text is between the start sequence (6 bytes) and the end sequence (6 bytes)
    return InternalEvent(Event(Paste(String(from_utf8_lossy=buffer[6 : len(buffer) - 6]))))


# ============================================================================
# UTF-8 Character Parsing
# ============================================================================


fn parse_utf8_char(buffer: Span[UInt8]) raises -> Optional[Codepoint]:
    """Parse a UTF-8 encoded character from the buffer.

    Args:
        buffer: The input buffer.

    Returns:
        Optional Codepoint if successfully parsed, None if more bytes needed.

    Raises:
        ParseError if the bytes are invalid UTF-8.
    """
    if len(buffer) == 0:
        return None

    try:
        var input = StringSlice(from_utf8=buffer)
        if input.count_codepoints() > 1:
            raise Error("Expected a single character, got multiple codepoints")
        return Codepoint.ord(input)
    except:
        pass

    # Manual UTF-8 parsing to determine if we have enough bytes for a valid character
    var first_byte = buffer[0]
    var required_bytes: Int

    # Determine number of bytes needed based on first byte
    if first_byte <= 0x7F:
        # ASCII: 0xxxxxxx
        required_bytes = 1
    elif first_byte >= 0xC0 and first_byte <= 0xDF:
        # 2 bytes: 110xxxxx 10xxxxxx
        required_bytes = 2
    elif first_byte >= 0xE0 and first_byte <= 0xEF:
        # 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx
        required_bytes = 3
    elif first_byte >= 0xF0 and first_byte <= 0xF7:
        # 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        required_bytes = 4
    else:
        # Invalid first byte (continuation byte or invalid)
        raise could_not_parse_event_error()

    # Check continuation bytes
    if required_bytes > 1 and len(buffer) > 1:
        for i in range(1, min(required_bytes, len(buffer))):
            var byte = buffer[i]
            if (byte & 0b1100_0000) != 0b1000_0000:
                raise could_not_parse_event_error()

    if len(buffer) < required_bytes:
        # Need more bytes
        return None

    # Decode the codepoint
    var codepoint: UInt32
    if required_bytes == 1:
        codepoint = UInt32(first_byte)
    elif required_bytes == 2:
        codepoint = ((UInt32(first_byte) & 0x1F) << 6) | (UInt32(buffer[1]) & 0x3F)
    elif required_bytes == 3:
        codepoint = ((UInt32(first_byte) & 0x0F) << 12) | ((UInt32(buffer[1]) & 0x3F) << 6) | (UInt32(buffer[2]) & 0x3F)
    else:
        codepoint = (
            ((UInt32(first_byte) & 0x07) << 18)
            | ((UInt32(buffer[1]) & 0x3F) << 12)
            | ((UInt32(buffer[2]) & 0x3F) << 6)
            | (UInt32(buffer[3]) & 0x3F)
        )

    var result = Codepoint.from_u32(codepoint)
    if not result:
        raise could_not_parse_event_error()

    return result.value()


# ============================================================================
# Helper: Character code to event
# ============================================================================


fn char_code_to_event(code: KeyCode) -> KeyEvent:
    """Convert a KeyCode to a KeyEvent, adding SHIFT modifier for uppercase.

    Args:
        code: The KeyCode.

    Returns:
        A KeyEvent with appropriate modifiers.
    """
    var modifiers = KeyModifiers.NONE
    if code.isa[Char]():
        if code[Char].char.is_ascii_upper():
            modifiers = KeyModifiers.SHIFT
    return KeyEvent(code, modifiers)


# ============================================================================
# CSI Sequence Parsing
# ============================================================================

comptime E_BYTE = "E".as_bytes()[0]
comptime O_BYTE = "O".as_bytes()[0]
comptime D_BYTE = "D".as_bytes()[0]
comptime C_BYTE = "C".as_bytes()[0]
comptime A_BYTE = "A".as_bytes()[0]
comptime B_BYTE = "B".as_bytes()[0]
comptime H_BYTE = "H".as_bytes()[0]
comptime F_BYTE = "F".as_bytes()[0]
comptime P_BYTE = "P".as_bytes()[0]
comptime S_BYTE = "S".as_bytes()[0]
comptime Z_BYTE = "Z".as_bytes()[0]
comptime M_BYTE = "M".as_bytes()[0]
comptime I_BYTE = "I".as_bytes()[0]
comptime Q_BYTE = "Q".as_bytes()[0]
comptime R_BYTE = "R".as_bytes()[0]
comptime LBRACKET_BYTE = "[".as_bytes()[0]
comptime CR_BYTE = "\r".as_bytes()[0]
comptime LF_BYTE = "\n".as_bytes()[0]
comptime TAB_BYTE = "\t".as_bytes()[0]
comptime SEMICOLON_BYTE = ";".as_bytes()[0]
comptime QUESTION_BYTE = "?".as_bytes()[0]
comptime TILDE_BYTE = "~".as_bytes()[0]
comptime u_BYTE = "u".as_bytes()[0]
comptime c_BYTE = "c".as_bytes()[0]
comptime m_BYTE = "m".as_bytes()[0]
comptime ZERO_BYTE = "0".as_bytes()[0]
comptime ONE_BYTE = "1".as_bytes()[0]
comptime TWO_BYTE = "2".as_bytes()[0]
comptime THREE_BYTE = "3".as_bytes()[0]
comptime FOUR_BYTE = "4".as_bytes()[0]
comptime NINE_BYTE = "9".as_bytes()[0]
comptime LESS_THAN_BYTE = "<".as_bytes()[0]
comptime DEL_BYTE = 0x7F
comptime CTRL_A = 0x01
comptime CTRL_Z = 0x1A
comptime CTRL_SPACE = 0x00
comptime CTRL_4 = 0x1C
comptime CTRL_7 = 0x1F


fn parse_csi(buffer: Span[UInt8]) raises -> Optional[InternalEvent]:
    """Parse a CSI (Control Sequence Introducer) escape sequence.

    CSI sequences start with ESC [ and are used for various terminal commands.

    Args:
        buffer: The input buffer starting with ESC [.

    Returns:
        Optional InternalEvent if successfully parsed.

    Raises:
        ParseError if the sequence cannot be parsed.
    """
    assert_starts_with[CSI](buffer)
    if len(buffer) == 2:
        return None

    var third_byte = buffer[2]

    if third_byte == ord("["):
        # ESC [ [ - Linux console F1-F5
        if len(buffer) == 3:
            return None

        var fourth_byte = buffer[3]
        if fourth_byte >= A_BYTE and fourth_byte <= E_BYTE:
            var fn_num = 1 + fourth_byte - A_BYTE
            return InternalEvent(Event(KeyEvent(FunctionKey(fn_num), KeyModifiers.NONE)))
        else:
            raise could_not_parse_event_error()

    elif third_byte == D_BYTE:
        return InternalEvent(Event(KeyEvent(Left(), KeyModifiers.NONE)))
    elif third_byte == C_BYTE:
        return InternalEvent(Event(KeyEvent(Right(), KeyModifiers.NONE)))
    elif third_byte == A_BYTE:
        return InternalEvent(Event(KeyEvent(Up(), KeyModifiers.NONE)))
    elif third_byte == B_BYTE:
        return InternalEvent(Event(KeyEvent(Down(), KeyModifiers.NONE)))
    elif third_byte == H_BYTE:
        return InternalEvent(Event(KeyEvent(Home(), KeyModifiers.NONE)))
    elif third_byte == F_BYTE:
        return InternalEvent(Event(KeyEvent(End(), KeyModifiers.NONE)))
    elif third_byte == Z_BYTE:
        return InternalEvent(Event(KeyEvent(BackTab(), KeyModifiers.SHIFT, KeyEventKind.Press)))
    elif third_byte == M_BYTE:
        return parse_csi_normal_mouse(buffer)
    elif third_byte == LESS_THAN_BYTE:
        return parse_csi_sgr_mouse(buffer)
    elif third_byte == I_BYTE:
        return InternalEvent(Event(FocusGained()))
    elif third_byte == O_BYTE:
        return InternalEvent(Event(FocusLost()))
    elif third_byte == SEMICOLON_BYTE:
        return parse_csi_modifier_key_code(buffer)
    elif third_byte == P_BYTE:
        return InternalEvent(Event(KeyEvent(FunctionKey(1), KeyModifiers.NONE)))
    elif third_byte == Q_BYTE:
        return InternalEvent(Event(KeyEvent(FunctionKey(2), KeyModifiers.NONE)))
    elif third_byte == S_BYTE:
        return InternalEvent(Event(KeyEvent(FunctionKey(4), KeyModifiers.NONE)))
    elif third_byte == QUESTION_BYTE:
        # ESC [ ? ... check last byte
        var last_byte = buffer[len(buffer) - 1]
        if last_byte == u_BYTE:
            return parse_csi_keyboard_enhancement_flags(buffer)
        elif last_byte == c_BYTE:
            return parse_csi_primary_device_attributes(buffer)
        else:
            return None
    elif third_byte >= ZERO_BYTE and third_byte <= NINE_BYTE:
        # Numbered escape code
        if len(buffer) == 3:
            return None

        # The final byte of a CSI sequence can be in the range 64-126
        var last_byte = buffer[len(buffer) - 1]
        if last_byte < 64 or last_byte > 126:
            return None

        # Check for bracketed paste
        if starts_with[CSI + "200~"](buffer):
            return parse_csi_bracketed_paste(buffer)

        if last_byte == M_BYTE:
            return parse_csi_rxvt_mouse(buffer)
        elif last_byte == TILDE_BYTE:
            return parse_csi_special_key_code(buffer)
        elif last_byte == u_BYTE:
            return parse_csi_u_encoded_key_code(buffer)
        elif last_byte == R_BYTE:
            return parse_csi_cursor_position(buffer)
        else:
            return parse_csi_modifier_key_code(buffer)
    else:
        raise could_not_parse_event_error()


# ============================================================================
# Main Event Parsing
# ============================================================================


fn parse_event(buffer: Span[UInt8], input_available: Bool) raises -> Optional[InternalEvent]:
    """Parse a terminal input event from a byte buffer.

    This is the main entry point for parsing terminal input.

    Args:
        buffer: The input buffer containing terminal input bytes.
        input_available: Whether more input may be available (affects ESC handling).

    Returns:
        Optional InternalEvent:
        - None: Wait for more bytes
        - Some(event): Successfully parsed event

    Raises:
        ParseError: Failed to parse event, buffer should be cleared.
    """
    if len(buffer) == 0:
        return None

    comptime ESC_BYTE = ESC.as_bytes()[0]
    var first_byte = buffer[0]
    if first_byte == ESC_BYTE:  # ESC
        if len(buffer) == 1:
            if input_available:
                # Possible ESC sequence, wait for more
                return None
            else:
                # Just ESC key
                return InternalEvent(Event(KeyEvent(Esc(), KeyModifiers.NONE)))
        else:
            var second_byte = buffer[1]
            if second_byte == O_BYTE:
                # ESC O - SS3 sequence
                if len(buffer) == 2:
                    return None

                var third_byte = buffer[2]
                if third_byte == D_BYTE:
                    return InternalEvent(Event(KeyEvent(Left(), KeyModifiers.NONE)))
                elif third_byte == C_BYTE:
                    return InternalEvent(Event(KeyEvent(Right(), KeyModifiers.NONE)))
                elif third_byte == A_BYTE:
                    return InternalEvent(Event(KeyEvent(Up(), KeyModifiers.NONE)))
                elif third_byte == B_BYTE:
                    return InternalEvent(Event(KeyEvent(Down(), KeyModifiers.NONE)))
                elif third_byte == H_BYTE:
                    return InternalEvent(Event(KeyEvent(Home(), KeyModifiers.NONE)))
                elif third_byte == F_BYTE:
                    return InternalEvent(Event(KeyEvent(End(), KeyModifiers.NONE)))
                elif third_byte >= P_BYTE and third_byte <= S_BYTE:
                    # F1-F4
                    var fn_num = 1 + third_byte - P_BYTE
                    return InternalEvent(Event(KeyEvent(FunctionKey(fn_num), KeyModifiers.NONE)))
                else:
                    raise could_not_parse_event_error()
            elif second_byte == LBRACKET_BYTE:
                return parse_csi(buffer)
            elif second_byte == ESC_BYTE:
                # Double ESC
                return InternalEvent(Event(KeyEvent(Esc(), KeyModifiers.NONE)))
            else:
                # Alt + key combination
                # Parse the rest recursively and add ALT modifier
                var result = parse_event(buffer[1:], input_available)
                if result:
                    ref event = result.value()
                    if event.is_event():
                        ref inner_event = event.as_event()
                        if inner_event.isa[KeyEvent]():
                            var key_event = inner_event[KeyEvent]
                            key_event.modifiers = key_event.modifiers | KeyModifiers.ALT
                            return InternalEvent(Event(key_event))
                        else:
                            return event.copy()
                    # # For non-key events (or non-modifiable events), reconstruct the event
                    # if event.is_cursor_position():
                    #     return InternalEvent(event.as_cursor_position())
                    # elif event.is_keyboard_enhancement_flags():
                    #     return InternalEvent(event.as_keyboard_enhancement_flags())
                    # elif event.is_primary_device_attributes():
                    #     return InternalEvent(event.as_primary_device_attributes())
                return None

    elif first_byte == CR_BYTE:  # \r or \n - Enter
        return InternalEvent(Event(KeyEvent(Enter(), KeyModifiers.NONE)))

    # TODO: Asssume stdin tty for now
    # \n = 0xA, which is also the keycode for Ctrl+J. The only reason we get
    # newlines as input is because the terminal converts \r into \n for us. When we
    # enter raw mode, we disable that, so \n no longer has any meaning - it's better to
    # use Ctrl+J. Waiting to handle it here means it gets picked up later
    elif first_byte == LF_BYTE and not is_terminal_raw(stdin):  # \n - Enter (only in cooked mode)
        return InternalEvent(Event(KeyEvent(Enter(), KeyModifiers.NONE)))

    elif first_byte == TAB_BYTE:  # \t - Tab
        return InternalEvent(Event(KeyEvent(Tab(), KeyModifiers.NONE)))

    elif first_byte == DEL_BYTE:  # DEL - Backspace
        return InternalEvent(Event(KeyEvent(Backspace(), KeyModifiers.NONE)))

    elif first_byte >= CTRL_A and first_byte <= CTRL_Z:  # Ctrl+A through Ctrl+Z
        var char_code = first_byte - CTRL_A + A_BYTE
        return InternalEvent(Event(KeyEvent(Char(char_code), KeyModifiers.CONTROL)))

    elif first_byte >= CTRL_4 and first_byte <= CTRL_7:  # Ctrl+4 through Ctrl+7
        var char_code = first_byte - CTRL_4 + FOUR_BYTE
        return InternalEvent(Event(KeyEvent(Char(char_code), KeyModifiers.CONTROL)))

    elif first_byte == CTRL_SPACE:  # Ctrl+Space
        return InternalEvent(Event(KeyEvent(Char(" "), KeyModifiers.CONTROL)))

    else:
        # Try to parse UTF-8 character
        var maybe_char = parse_utf8_char(buffer)
        if not maybe_char:
            return None
        var c = maybe_char.value()
        # var keycode = KeyCode(Char(String(from_utf8_lossy=buffer)))
        var key_event = char_code_to_event(KeyCode(Char(c)))
        return InternalEvent(Event(key_event))
