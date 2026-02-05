"""Examples demonstrating the usage of event types from mist.terminal.event.

This file shows how to create and work with keyboard events, mouse events,
and other terminal events using the Mojo event system.
"""

from mist.event.event import (
    Char,
    Down,
    Enter,
    Esc,
    Event,
    FocusGained,
    FocusLost,
    FunctionKey,
    KeyboardEnhancementFlags,
    KeyCode,
    KeyEvent,
    KeyEventKind,
    KeyEventState,
    KeyModifiers,
    Left,
    MediaKeyCode,
    ModifierKeyCode,
    MouseButton,
    MouseEvent,
    MouseEventKind,
    MouseMoved,
    MousePress,
    MouseRelease,
    MouseScrollDown,
    Paste,
    Resize,
    Right,
    Tab,
    Up,
)


fn example_key_events() raises:
    """Demonstrates creating and working with keyboard events."""
    print("=== Key Event Examples ===\n")

    # Create a simple key press event for the 'a' key
    var key_a = KeyEvent(Char("a"), KeyModifiers.NONE)
    print("Created key event for 'a':")
    print("  Code: " + key_a.code.__str__())
    print("  Is press: " + String(key_a.is_press()))
    print()

    # Create a key event with modifiers (Ctrl+C)
    var ctrl_c = KeyEvent(Char("c"), KeyModifiers.CONTROL)
    print("Created Ctrl+C event:")
    print("  Modifiers: " + ctrl_c.modifiers.__str__())
    print()

    # Create a key event with multiple modifiers (Ctrl+Shift+S)
    var ctrl_shift_s = KeyEvent(
        Char("S"),
        KeyModifiers.CONTROL | KeyModifiers.SHIFT
    )
    print("Created Ctrl+Shift+S event:")
    print("  Has CONTROL: " + String(ctrl_shift_s.modifiers.contains(KeyModifiers.CONTROL)))
    print("  Has SHIFT: " + String(ctrl_shift_s.modifiers.contains(KeyModifiers.SHIFT)))
    print()

    # Create function key events
    var f1_key = KeyEvent(FunctionKey(1), KeyModifiers.NONE)
    print("Created F1 key event:")
    print("  Code: " + f1_key.code.__str__())
    # print("  Is F1: " + String(f1_key.code.is_function_key(1)))
    # print("  Is F2: " + String(f1_key.code.is_function_key(2)))
    # print()

    # Create special key events
    var escape = KeyEvent(Esc(), KeyModifiers.NONE)
    var enter = KeyEvent(Enter(), KeyModifiers.NONE)
    var tab = KeyEvent(Tab(), KeyModifiers.NONE)
    print("Special keys:")
    print("  Escape: " + escape.code.__str__())
    print("  Enter: " + enter.code.__str__())
    print("  Tab: " + tab.code.__str__())
    print()

    # Create arrow key events
    var up = KeyEvent(Up(), KeyModifiers.NONE)
    var down = KeyEvent(Down(), KeyModifiers.NONE)
    var left = KeyEvent(Left(), KeyModifiers.NONE)
    var right = KeyEvent(Right(), KeyModifiers.NONE)
    print("Arrow keys:")
    print("  Up: " + up.code.__str__())
    print("  Down: " + down.code.__str__())
    print("  Left: " + left.code.__str__())
    print("  Right: " + right.code.__str__())
    print()

    # Create key release event
    var key_release = KeyEvent(
        Char("x"),
        KeyModifiers.NONE,
        KeyEventKind.Release
    )
    print("Key release event:")
    print("  Is press:", key_release.is_press())
    print("  Is release:", key_release.is_release())
    print()


fn example_mouse_events():
    """Demonstrates creating and working with mouse events."""
    print("=== Mouse Event Examples ===\n")

    # Create a left mouse button click event
    var event = MouseEventKind(MousePress(MouseButton.Left))
    var left_click = MouseEvent(
        kind=MouseEventKind(MousePress(MouseButton.Left)),
        column=10,
        row=5,
        modifiers=KeyModifiers.NONE
    )
    print("Created left click at (10, 5):")
    print("  Column: ", left_click.column)
    print("  Row: ", left_click.row)
    print("\n")

    # Create a right click with Ctrl held
    var ctrl_right_click = MouseEvent(
        MousePress(MouseButton.Right),
        column=20,
        row=15,
        modifiers=KeyModifiers.CONTROL
    )
    print("Created Ctrl+Right click at (20, 15):")
    print("  Has CONTROL: " + String(ctrl_right_click.modifiers.contains(KeyModifiers.CONTROL)))
    print("\n")

    # Create mouse release event
    var mouse_release = MouseEvent(
        MouseRelease(MouseButton.Left),
        column=10,
        row=5,
        modifiers=KeyModifiers.NONE
    )
    print("Created mouse release event")
    print("\n")

    # Create mouse move event
    var mouse_move = MouseEvent(
        MouseMoved(),
        column=50,
        row=25,
        modifiers=KeyModifiers.NONE
    )
    print("Created mouse move to (50, 25)")
    print("\n")

    # Create scroll event
    var scroll_down = MouseEvent(
        MouseScrollDown(),
        column=30,
        row=10,
        modifiers=KeyModifiers.NONE
    )
    print("Created scroll down event at (30, 10)")
    print("\n")


fn example_terminal_events() raises:
    """Demonstrates creating and working with terminal events."""
    print("=== Terminal Event Examples ===\n")

    # Focus events
    var focus_gained: Event = FocusGained()
    var focus_lost: Event = FocusLost()
    print("Focus events:")
    print("  Focus gained is_focus_gained: ", focus_gained.isa[FocusGained]())
    print("  Focus lost is_focus_lost: ", focus_lost.isa[FocusLost]())
    print("\n")

    # Resize event
    var resize: Event = Resize(columns=120, rows=40)
    print("Resize event:")
    print("  Is resize: ", resize.isa[Resize]())
    var maybe_size = resize.as_resize_event()
    if maybe_size:
        var size = maybe_size.value()
        print("  New size: " + String(Int(size[0])) + "x" + String(Int(size[1])))
    print()

    # Paste event
    var paste: Event = Paste("Hello, World!")
    print("Paste event:")
    print("  Is paste: ", paste.isa[Paste]())
    var maybe_content = paste.as_paste_event()
    if maybe_content:
        print("  Content: " + maybe_content.value())
    print()

    # Key event wrapped in Event
    var key_event = KeyEvent(Char("q"), KeyModifiers.CONTROL)
    var event: Event = key_event
    print("Key event (Ctrl+Q) wrapped in Event:")
    print("  Is key: ", event.isa[KeyEvent]())
    print("  Is key press: ", event.is_key_press())
    var maybe_key = event.as_key_event()
    if maybe_key:
        var key = maybe_key.value()
        print("  Key code: ", key.code)
    print("\n")


fn example_keyboard_enhancement_flags():
    """Demonstrates keyboard enhancement flags for kitty protocol."""
    print("=== Keyboard Enhancement Flags Examples ===\n")

    # Create flags for disambiguating escape codes
    var flags = KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES

    # Combine multiple flags
    var combined_flags = (
        KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES
        | KeyboardEnhancementFlags.REPORT_EVENT_TYPES
    )

    print("Flags operations:")
    print("  Has DISAMBIGUATE_ESCAPE_CODES: " + String(
        combined_flags.contains(KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES)
    ))
    print("  Has REPORT_EVENT_TYPES: " + String(
        combined_flags.contains(KeyboardEnhancementFlags.REPORT_EVENT_TYPES)
    ))
    print("  Has REPORT_ALTERNATE_KEYS: " + String(
        combined_flags.contains(KeyboardEnhancementFlags.REPORT_ALTERNATE_KEYS)
    ))
    print("  Bits value: " + String(Int(combined_flags.bits())))
    print()


# fn example_media_and_modifier_keys():
#     """Demonstrates media keys and modifier key codes."""
#     print("=== Media and Modifier Keys Examples ===\n")

#     # Media keys
#     var play_key = KeyCode.Media(MediaKeyCode.Play)
#     var pause_key = KeyCode.Media(MediaKeyCode.Pause)
#     var volume_up = KeyCode.Media(MediaKeyCode.RaiseVolume)

#     print("Media keys:")
#     print("  Play: " + play_key.__str__())
#     print("  Pause: " + pause_key.__str__())
#     print("  Volume Up: " + volume_up.__str__())
#     print("  Is Play media key: " + String(play_key.is_media_key(MediaKeyCode.Play)))
#     print()

#     # Modifier keys (as KeyCode, not KeyModifiers)
#     var left_shift = KeyCode.Modifier(ModifierKeyCode.LeftShift)
#     var right_ctrl = KeyCode.Modifier(ModifierKeyCode.RightControl)
#     var left_cmd = KeyCode.Modifier(ModifierKeyCode.LeftSuper)

#     print("Modifier keys as KeyCode:")
#     print("  Left Shift: " + left_shift.__str__())
#     print("  Right Control: " + right_ctrl.__str__())
#     print("  Left Command: " + left_cmd.__str__())
#     print()


fn example_key_code_helpers() raises:
    """Demonstrates KeyCode helper methods."""
    print("=== KeyCode Helper Methods ===\n")

    var char_a = Char("a")
    var char_space = Char(" ")
    var f5 = FunctionKey(5)

    print("Character checks:")
    print("  'a' is_char('a'): ", char_a == "a")
    print("  'a' is_char('b'): ", char_a == "b")
    print("\n")

    # print("as_char() method:")
    # var maybe_char = char_a.as_char()
    # if maybe_char:
    #     print("  char_a as_char: '" + maybe_char.value() + "'")
    # print()

    # print("Function key number:")
    # var maybe_fkey = f5.get_function_key_number()
    # if maybe_fkey:
    #     print("  F5 function key number: " + String(Int(maybe_fkey.value())))
    # print()

    # print("Special characters:")
    # print("  Space displays as: " + char_space.__str__())
    # print()


fn main() raises:
    """Run all examples."""
    print("╔════════════════════════════════════════════════════════════╗")
    print("║           Mist Terminal Event Examples                     ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print("\n")

    example_key_events()
    example_mouse_events()
    example_terminal_events()
    example_keyboard_enhancement_flags()
    # example_media_and_modifier_keys()
    example_key_code_helpers()

    print("All examples completed successfully!")
