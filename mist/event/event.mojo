"""Event module for terminal input handling.

This module provides functionality to read keyboard, mouse, and terminal resize events.
It includes types for representing various input events and their properties.

**Important:** Make sure to enable raw mode for keyboard events to work properly.

## Mouse and Focus Events

Mouse and focus events are not enabled by default. You have to enable them with
the EnableMouseCapture / EnableFocusChange commands.
"""

from utils import Variant


# ============================================================================
# Keyboard Enhancement Flags (bitflags)
# ============================================================================


@register_passable("trivial")
struct KeyboardEnhancementFlags(Equatable, ImplicitlyCopyable):
    """Represents special flags that tell compatible terminals to add extra information to keyboard events.

    See https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement for more information.
    """

    var value: UInt8

    # Represent Escape and modified keys using CSI-u sequences, so they can be unambiguously read.
    comptime DISAMBIGUATE_ESCAPE_CODES = KeyboardEnhancementFlags(0b0000_0001)
    # Add extra events with KeyEvent.kind set to KeyEventKind::Repeat or KeyEventKind::Release
    # when keys are autorepeated or released.
    comptime REPORT_EVENT_TYPES = KeyboardEnhancementFlags(0b0000_0010)
    # Send alternate keycodes in addition to the base keycode.
    comptime REPORT_ALTERNATE_KEYS = KeyboardEnhancementFlags(0b0000_0100)
    # Represent all keyboard events as CSI-u sequences.
    comptime REPORT_ALL_KEYS_AS_ESCAPE_CODES = KeyboardEnhancementFlags(0b0000_1000)

    fn __init__(out self, value: UInt8):
        self.value = value

    fn __or__(self, other: Self) -> Self:
        return Self(self.value | other.value)

    fn __and__(self, other: Self) -> Self:
        return Self(self.value & other.value)

    fn __xor__(self, other: Self) -> Self:
        return Self(self.value ^ other.value)

    fn __invert__(self) -> Self:
        return Self(~self.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn contains(self, other: Self) -> Bool:
        """Check if this flag set contains all flags from other."""
        return (self.value & other.value) == other.value

    fn insert(mut self, other: Self):
        """Insert the specified flags."""
        self.value = self.value | other.value

    fn remove(mut self, other: Self):
        """Remove the specified flags."""
        self.value = self.value & (~other.value)

    fn bits(self) -> UInt8:
        """Return the raw bits value."""
        return self.value

    fn is_empty(self) -> Bool:
        """Check if no flags are set."""
        return self.value == 0


# ============================================================================
# Key Modifiers (bitflags)
# ============================================================================


@fieldwise_init
@register_passable("trivial")
struct KeyModifiers(Equatable, ImplicitlyCopyable, Stringable, Writable):
    """Represents key modifiers (shift, control, alt, etc.).

    Note: SUPER, HYPER, and META can only be read if
    KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES has been enabled.
    """

    var value: UInt8

    comptime NONE = KeyModifiers(0b0000_0000)
    comptime SHIFT = KeyModifiers(0b0000_0001)
    comptime CONTROL = KeyModifiers(0b0000_0010)
    comptime ALT = KeyModifiers(0b0000_0100)
    comptime SUPER = KeyModifiers(0b0000_1000)
    comptime HYPER = KeyModifiers(0b0001_0000)
    comptime META = KeyModifiers(0b0010_0000)

    fn __or__(self, other: Self) -> Self:
        return Self(self.value | other.value)

    fn __and__(self, other: Self) -> Self:
        return Self(self.value & other.value)

    fn __xor__(self, other: Self) -> Self:
        return Self(self.value ^ other.value)

    fn __invert__(self) -> Self:
        return Self(~self.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn contains(self, other: Self) -> Bool:
        """Check if this modifier set contains all modifiers from other."""
        return (self.value & other.value) == other.value

    fn insert(mut self, other: Self):
        """Insert the specified modifiers."""
        self.value = self.value | other.value

    fn remove(mut self, other: Self):
        """Remove the specified modifiers."""
        self.value = self.value & (~other.value)

    fn is_empty(self) -> Bool:
        """Check if no modifiers are set."""
        return self.value == 0

    fn write_to(self, mut writer: Some[Writer]):
        """Format the key modifiers joined by a '+' character.

        On macOS, control is "Control", alt is "Option", and super is "Command".
        """
        var parts = List[String]()
        if self.contains(Self.SHIFT):
            parts.append("Shift")
        if self.contains(Self.CONTROL):
            parts.append("Control")
        if self.contains(Self.ALT):
            parts.append("Option")  # macOS style
        if self.contains(Self.SUPER):
            parts.append("Command")  # macOS style
        if self.contains(Self.HYPER):
            parts.append("Hyper")
        if self.contains(Self.META):
            parts.append("Meta")

        if len(parts) == 0:
            return

        writer.write("+".join(parts))

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Key Event State (bitflags)
# ============================================================================


@fieldwise_init
@register_passable("trivial")
struct KeyEventState(Equatable, ImplicitlyCopyable, Stringable, Writable):
    """Represents extra state about the key event.

    Note: This state can only be read if
    KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES has been enabled.
    """

    var value: UInt8

    comptime NONE = KeyEventState(0b0000_0000)
    # The key event origins from the keypad.
    comptime KEYPAD = KeyEventState(0b0000_0001)
    # Caps Lock was enabled for this key event.
    comptime CAPS_LOCK = KeyEventState(0b0000_0010)
    # Num Lock was enabled for this key event.
    comptime NUM_LOCK = KeyEventState(0b0000_0100)

    fn __or__(self, other: Self) -> Self:
        return Self(self.value | other.value)

    fn __and__(self, other: Self) -> Self:
        return Self(self.value & other.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        """Format the key event state joined by a '+' character."""
        var parts = List[String]()
        if self.contains(Self.KEYPAD):
            parts.append("Keypad")
        if self.contains(Self.CAPS_LOCK):
            parts.append("Caps Lock")
        if self.contains(Self.NUM_LOCK):
            parts.append("Num Lock")

        if len(parts) == 0:
            return

        writer.write("+".join(parts))

    fn __str__(self) -> String:
        return String.write(self)

    fn contains(self, other: Self) -> Bool:
        """Check if this state contains all flags from other."""
        return (self.value & other.value) == other.value

    fn is_empty(self) -> Bool:
        """Check if no state flags are set."""
        return self.value == 0


# ============================================================================
# Key Event Kind (using struct constants since no enums)
# ============================================================================


@fieldwise_init
@register_passable("trivial")
struct KeyEventKind(Equatable, ImplicitlyCopyable, Stringable, Writable):
    """Represents a keyboard event kind."""

    var value: UInt8

    comptime Press = KeyEventKind(0)
    comptime Repeat = KeyEventKind(1)
    comptime Release = KeyEventKind(2)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        if self == Self.Press:
            writer.write("Press")
        elif self == Self.Repeat:
            writer.write("Repeat")
        else:
            writer.write("Release")

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Media Key Code (using struct constants since no enums)
# ============================================================================


@fieldwise_init
@register_passable("trivial")
struct MediaKeyCode(Equatable, ImplicitlyCopyable, KeyType):
    """Represents a media key."""

    var value: UInt8

    comptime Play = MediaKeyCode(0)
    comptime Pause = MediaKeyCode(1)
    comptime PlayPause = MediaKeyCode(2)
    comptime Reverse = MediaKeyCode(3)
    comptime Stop = MediaKeyCode(4)
    comptime FastForward = MediaKeyCode(5)
    comptime Rewind = MediaKeyCode(6)
    comptime TrackNext = MediaKeyCode(7)
    comptime TrackPrevious = MediaKeyCode(8)
    comptime Record = MediaKeyCode(9)
    comptime LowerVolume = MediaKeyCode(10)
    comptime RaiseVolume = MediaKeyCode(11)
    comptime MuteVolume = MediaKeyCode(12)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        if self == Self.Play:
            writer.write("Play")
        elif self == Self.Pause:
            writer.write("Pause")
        elif self == Self.PlayPause:
            writer.write("Play/Pause")
        elif self == Self.Reverse:
            writer.write("Reverse")
        elif self == Self.Stop:
            writer.write("Stop")
        elif self == Self.FastForward:
            writer.write("Fast Forward")
        elif self == Self.Rewind:
            writer.write("Rewind")
        elif self == Self.TrackNext:
            writer.write("Next Track")
        elif self == Self.TrackPrevious:
            writer.write("Previous Track")
        elif self == Self.Record:
            writer.write("Record")
        elif self == Self.LowerVolume:
            writer.write("Lower Volume")
        elif self == Self.RaiseVolume:
            writer.write("Raise Volume")
        else:
            writer.write("Mute Volume")

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Modifier Key Code (using struct constants since no enums)
# ============================================================================


@register_passable("trivial")
@fieldwise_init
struct ModifierKeyCode(Equatable, ImplicitlyCopyable, KeyType, Stringable):
    """Represents a modifier key.

    On macOS, control is "Control", alt is "Option", and super is "Command".
    """

    var value: UInt8

    comptime LeftShift = ModifierKeyCode(0)
    comptime LeftControl = ModifierKeyCode(1)
    comptime LeftAlt = ModifierKeyCode(2)
    comptime LeftSuper = ModifierKeyCode(3)
    comptime LeftHyper = ModifierKeyCode(4)
    comptime LeftMeta = ModifierKeyCode(5)
    comptime RightShift = ModifierKeyCode(6)
    comptime RightControl = ModifierKeyCode(7)
    comptime RightAlt = ModifierKeyCode(8)
    comptime RightSuper = ModifierKeyCode(9)
    comptime RightHyper = ModifierKeyCode(10)
    comptime RightMeta = ModifierKeyCode(11)
    comptime IsoLevel3Shift = ModifierKeyCode(12)
    comptime IsoLevel5Shift = ModifierKeyCode(13)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        """Format the modifier key (macOS style)."""
        if self == Self.LeftShift:
            writer.write("Left Shift")
        elif self == Self.LeftControl:
            writer.write("Left Control")
        elif self == Self.LeftAlt:
            writer.write("Left Option")  # macOS style
        elif self == Self.LeftSuper:
            writer.write("Left Command")  # macOS style
        elif self == Self.LeftHyper:
            writer.write("Left Hyper")
        elif self == Self.LeftMeta:
            writer.write("Left Meta")
        elif self == Self.RightShift:
            writer.write("Right Shift")
        elif self == Self.RightControl:
            writer.write("Right Control")
        elif self == Self.RightAlt:
            writer.write("Right Option")  # macOS style
        elif self == Self.RightSuper:
            writer.write("Right Command")  # macOS style
        elif self == Self.RightHyper:
            writer.write("Right Hyper")
        elif self == Self.RightMeta:
            writer.write("Right Meta")
        elif self == Self.IsoLevel3Shift:
            writer.write("Iso Level 3 Shift")
        else:
            writer.write("Iso Level 5 Shift")

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Key Code
# ============================================================================


trait KeyType(Writable):
    """Marker trait for key types."""

    pass


@register_passable("trivial")
@fieldwise_init
struct Backspace(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Backspace")


@register_passable("trivial")
@fieldwise_init
struct Enter(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Enter")


@register_passable("trivial")
@fieldwise_init
struct Left(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Left")


@register_passable("trivial")
@fieldwise_init
struct Right(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Right")


@register_passable("trivial")
@fieldwise_init
struct Up(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Up")


@register_passable("trivial")
@fieldwise_init
struct Down(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Down")


@register_passable("trivial")
@fieldwise_init
struct Home(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Home")


@register_passable("trivial")
@fieldwise_init
struct End(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("End")


@register_passable("trivial")
@fieldwise_init
struct PageUp(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Page Up")


@register_passable("trivial")
@fieldwise_init
struct PageDown(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Page Down")


@register_passable("trivial")
@fieldwise_init
struct Tab(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Tab")


@register_passable("trivial")
@fieldwise_init
struct BackTab(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Back Tab")


@register_passable("trivial")
@fieldwise_init
struct Delete(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Delete")


@register_passable("trivial")
@fieldwise_init
struct Insert(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Insert")


@register_passable("trivial")
@fieldwise_init
struct Null(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Null")


@register_passable("trivial")
@fieldwise_init
struct Esc(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Esc")


@register_passable("trivial")
@fieldwise_init
struct CapsLock(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Caps Lock")


@register_passable("trivial")
@fieldwise_init
struct ScrollLock(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Scroll Lock")


@register_passable("trivial")
@fieldwise_init
struct NumLock(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Num Lock")


@register_passable("trivial")
@fieldwise_init
struct PrintScreen(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Print Screen")


@register_passable("trivial")
@fieldwise_init
struct Pause(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Pause")


@register_passable("trivial")
@fieldwise_init
struct Menu(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Menu")


@register_passable("trivial")
@fieldwise_init
struct KeypadBegin(ImplicitlyCopyable, KeyType):
    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("Keypad Begin")


@register_passable("trivial")
@fieldwise_init
struct FunctionKey(ImplicitlyCopyable, KeyType):
    var number: UInt8

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("F", self.number)


@fieldwise_init
struct Char(Equatable, ImplicitlyCopyable, KeyType):
    var char: Codepoint

    fn __init__(out self, char: UInt32) raises:
        var c = Codepoint.from_u32(char)
        if not c:
            raise Error("Invalid Unicode codepoint: ", char)
        self.char = c.value()

    fn __init__(out self, char: UInt8):
        self.char = Codepoint(char)

    fn __init__(out self, char: StringSlice):
        self.char = Codepoint.ord(char)

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.char)

    fn __eq__(self, other: Self) -> Bool:
        return self.char == other.char

    fn __eq__(self, other: StringSlice) -> Bool:
        return self.char == Codepoint.ord(other)


@fieldwise_init
struct KeyCode(Equatable, ImplicitlyCopyable, Stringable, Writable):
    """Represents a key.

    This struct uses a type tag and a value field to represent different key types.
    Use the static methods to create specific key codes.
    """

    var value: Variant[
        Backspace,
        Enter,
        Left,
        Right,
        Up,
        Down,
        Home,
        End,
        PageUp,
        PageDown,
        Tab,
        BackTab,
        Delete,
        Insert,
        Null,
        Esc,
        CapsLock,
        ScrollLock,
        NumLock,
        PrintScreen,
        Pause,
        Menu,
        KeypadBegin,
        FunctionKey,
        Char,
        MediaKeyCode,
        ModifierKeyCode,
    ]

    @implicit
    fn __init__(out self, value: Backspace):
        self.value = value

    @implicit
    fn __init__(out self, value: Enter):
        self.value = value

    @implicit
    fn __init__(out self, value: Left):
        self.value = value

    @implicit
    fn __init__(out self, value: Right):
        self.value = value

    @implicit
    fn __init__(out self, value: Up):
        self.value = value

    @implicit
    fn __init__(out self, value: Down):
        self.value = value

    @implicit
    fn __init__(out self, value: Home):
        self.value = value

    @implicit
    fn __init__(out self, value: End):
        self.value = value

    @implicit
    fn __init__(out self, value: PageUp):
        self.value = value

    @implicit
    fn __init__(out self, value: PageDown):
        self.value = value

    @implicit
    fn __init__(out self, value: Tab):
        self.value = value

    @implicit
    fn __init__(out self, value: BackTab):
        self.value = value

    @implicit
    fn __init__(out self, value: Delete):
        self.value = value

    @implicit
    fn __init__(out self, value: Insert):
        self.value = value

    @implicit
    fn __init__(out self, value: Null):
        self.value = value

    @implicit
    fn __init__(out self, value: Esc):
        self.value = value

    @implicit
    fn __init__(out self, value: CapsLock):
        self.value = value

    @implicit
    fn __init__(out self, value: ScrollLock):
        self.value = value

    @implicit
    fn __init__(out self, value: NumLock):
        self.value = value

    @implicit
    fn __init__(out self, value: PrintScreen):
        self.value = value

    @implicit
    fn __init__(out self, value: Pause):
        self.value = value

    @implicit
    fn __init__(out self, value: Menu):
        self.value = value

    @implicit
    fn __init__(out self, value: KeypadBegin):
        self.value = value

    @implicit
    fn __init__(out self, value: FunctionKey):
        self.value = value

    @implicit
    fn __init__(out self, value: Char):
        self.value = value

    @implicit
    fn __init__(out self, value: MediaKeyCode):
        self.value = value

    @implicit
    fn __init__(out self, value: ModifierKeyCode):
        self.value = value

    # fn __eq__(self, other: Self) -> Bool:
    #     return self._type == other._type and self._value == other._value

    fn isa[T: KeyType](self) -> Bool:
        """Returns True if the key code is of type T."""
        return self.value.isa[T]()

    fn __getitem__[T: KeyType](ref self) -> ref[self.value] T:
        """Returns the key code as type T."""
        return self.value[T]

    fn write_to(self, mut writer: Some[Writer]) -> None:
        """Format the KeyCode.

        On macOS, Backspace is "Delete", Delete is "Fwd Del", and Enter is "Return".
        """
        if self.isa[Backspace]():
            writer.write(self[Backspace])
        elif self.isa[Enter]():
            writer.write(self[Enter])
        elif self.isa[Left]():
            writer.write(self[Left])
        elif self.isa[Right]():
            writer.write(self[Right])
        elif self.isa[Up]():
            writer.write(self[Up])
        elif self.isa[Down]():
            writer.write(self[Down])
        elif self.isa[Home]():
            writer.write(self[Home])
        elif self.isa[End]():
            writer.write(self[End])
        elif self.isa[PageUp]():
            writer.write(self[PageUp])
        elif self.isa[PageDown]():
            writer.write(self[PageDown])
        elif self.isa[Tab]():
            writer.write(self[Tab])
        elif self.isa[BackTab]():
            writer.write(self[BackTab])
        elif self.isa[Delete]():
            writer.write(self[Delete])
        elif self.isa[Insert]():
            writer.write(self[Insert])
        elif self.isa[Null]():
            writer.write(self[Null])
        elif self.isa[Esc]():
            writer.write(self[Esc])
        elif self.isa[CapsLock]():
            writer.write(self[CapsLock])
        elif self.isa[ScrollLock]():
            writer.write(self[ScrollLock])
        elif self.isa[NumLock]():
            writer.write(self[NumLock])
        elif self.isa[PrintScreen]():
            writer.write(self[PrintScreen])
        elif self.isa[Pause]():
            writer.write(self[Pause])
        elif self.isa[Menu]():
            writer.write(self[Menu])
        elif self.isa[KeypadBegin]():
            writer.write(self[KeypadBegin])
        elif self.isa[FunctionKey]():
            writer.write(self[FunctionKey])
        elif self.isa[Char]():
            writer.write(self[Char])
        elif self.isa[MediaKeyCode]():
            writer.write(self[MediaKeyCode])
        elif self.isa[ModifierKeyCode]():
            writer.write(self[ModifierKeyCode])
        else:
            writer.write("Unknown KeyCode")

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Mouse Button
# ============================================================================


@register_passable("trivial")
@fieldwise_init
struct MouseButton(Equatable, ImplicitlyCopyable, Stringable, Writable):
    """Represents a mouse button."""

    var value: UInt8

    comptime Left = MouseButton(0)
    comptime Right = MouseButton(1)
    comptime Middle = MouseButton(2)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        if self == Self.Left:
            writer.write("Left")
        elif self == Self.Right:
            writer.write("Right")
        else:
            writer.write("Middle")

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Mouse Event Kind (using Variant since it can carry data)
# ============================================================================


trait MouseEventType(Writable):
    """Marker trait for mouse event types."""

    ...


@register_passable("trivial")
@fieldwise_init
struct MousePress(Equatable, ImplicitlyCopyable, MouseEventType):
    """Pressed mouse button."""

    var button: MouseButton

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MousePress(", self.button, ")")


@register_passable("trivial")
@fieldwise_init
struct MouseRelease(Equatable, ImplicitlyCopyable, MouseEventType):
    """Released mouse button."""

    var button: MouseButton

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseRelease(", self.button, ")")


@register_passable("trivial")
@fieldwise_init
struct MouseDrag(Equatable, ImplicitlyCopyable, MouseEventType):
    """Moved the mouse cursor while pressing a button."""

    var button: MouseButton

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseDrag(", self.button, ")")


@register_passable("trivial")
@fieldwise_init
struct MouseMoved(Equatable, ImplicitlyCopyable, MouseEventType):
    """Moved the mouse cursor while not pressing a mouse button."""

    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseMoved()")


@register_passable("trivial")
@fieldwise_init
struct MouseScrollDown(Equatable, ImplicitlyCopyable, MouseEventType):
    """Scrolled mouse wheel downwards (towards the user)."""

    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseScrollDown()")


@register_passable("trivial")
@fieldwise_init
struct MouseScrollUp(Equatable, ImplicitlyCopyable, MouseEventType):
    """Scrolled mouse wheel upwards (away from the user)."""

    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseScrollUp()")


@register_passable("trivial")
@fieldwise_init
struct MouseScrollLeft(Equatable, ImplicitlyCopyable, MouseEventType):
    """Scrolled mouse wheel left (mostly on a laptop touchpad)."""

    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseScrollLeft()")


@register_passable("trivial")
@fieldwise_init
struct MouseScrollRight(Equatable, ImplicitlyCopyable, MouseEventType):
    """Scrolled mouse wheel right (mostly on a laptop touchpad)."""

    var remove_later: Bool
    """Only here because of a bug in the complier with empty structs."""

    fn __init__(out self):
        self.remove_later = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("MouseScrollRight()")


# ============================================================================
# Mouse Event
# ============================================================================


struct MouseEventKind(ImplicitlyCopyable, Stringable, Writable):
    var event: Variant[
        MousePress,
        MouseRelease,
        MouseDrag,
        MouseMoved,
        MouseScrollDown,
        MouseScrollUp,
        MouseScrollLeft,
        MouseScrollRight,
    ]

    @implicit
    fn __init__(out self, value: MousePress):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseRelease):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseDrag):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseMoved):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseScrollDown):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseScrollUp):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseScrollLeft):
        self.event = value

    @implicit
    fn __init__(out self, value: MouseScrollRight):
        self.event = value

    fn isa[T: MouseEventType](self) -> Bool:
        """Returns True if the mouse event kind is of type T."""
        return self.event.isa[T]()

    fn __getitem__[T: MouseEventType](ref self) -> ref[self.event] T:
        """Returns the mouse event kind as type T."""
        return self.event[T]

    fn write_to(self, mut writer: Some[Writer]):
        if self.isa[MousePress]():
            writer.write(self[MousePress])
        elif self.isa[MouseRelease]():
            writer.write(self[MouseRelease])
        elif self.isa[MouseDrag]():
            writer.write(self[MouseDrag])
        elif self.isa[MouseMoved]():
            writer.write(self[MouseMoved])
        elif self.isa[MouseScrollDown]():
            writer.write(self[MouseScrollDown])
        elif self.isa[MouseScrollUp]():
            writer.write(self[MouseScrollUp])
        elif self.isa[MouseScrollLeft]():
            writer.write(self[MouseScrollLeft])
        elif self.isa[MouseScrollRight]():
            writer.write(self[MouseScrollRight])
        else:
            writer.write("Unknown MouseEventKind")

    fn __str__(self) -> String:
        return String.write(self)


@fieldwise_init
struct MouseEvent(EventType, ImplicitlyCopyable, Writable):
    """Represents a mouse event.

    ## Platform-specific Notes

    ### Mouse Buttons
    Some platforms/terminals do not report mouse button for the
    MouseRelease and MouseDrag events. MouseButton.Left is returned if we don't know
    which button was used.

    ### Key Modifiers
    Some platforms/terminals do not report all key modifier combinations for all
    mouse event types. For example - macOS reports Ctrl + left mouse button click
    as a right mouse button click.
    """

    var kind: MouseEventKind
    """The kind of mouse event that was caused."""
    var column: UInt16
    """The column that the event occurred on."""
    var row: UInt16
    """The row that the event occurred on."""
    var modifiers: KeyModifiers
    """The key modifiers active when the event occurred."""

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(
            "MouseEvent(kind=",
            self.kind,
            ", column=",
            self.column,
            ", row=",
            self.row,
            ", modifiers=",
            self.modifiers,
            ")",
        )


# ============================================================================
# Key Event
# ============================================================================


trait InternalEventType(Writable):
    """Marker trait for internal event types."""

    pass


trait EventType(Writable):
    """Event Type marker trait."""

    pass


@fieldwise_init
struct KeyEvent(Equatable, EventType, ImplicitlyCopyable, Stringable, Writable):
    """Represents a key event."""

    var code: KeyCode
    """The key itself."""
    var modifiers: KeyModifiers
    """Additional key modifiers."""
    var kind: KeyEventKind
    """Kind of event (Press, Repeat, Release).

    Only set if:
    - Unix: KeyboardEnhancementFlags.REPORT_EVENT_TYPES has been enabled.
    """
    var state: KeyEventState
    """Keyboard state.

    Only set if KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES has been enabled.
    """

    fn __init__(out self, code: KeyCode, modifiers: KeyModifiers, kind: KeyEventKind = KeyEventKind.Press):
        """Create a new KeyEvent with specified kind and empty state."""
        self.code = code
        self.modifiers = modifiers
        self.kind = kind
        self.state = KeyEventState.NONE

    fn is_press(self) -> Bool:
        """Returns whether the key event is a press event."""
        return self.kind == KeyEventKind.Press

    fn is_release(self) -> Bool:
        """Returns whether the key event is a release event."""
        return self.kind == KeyEventKind.Release

    fn is_repeat(self) -> Bool:
        """Returns whether the key event is a repeat event."""
        return self.kind == KeyEventKind.Repeat

    fn _normalize_case(self) raises -> KeyEvent:
        """Normalize case so that SHIFT modifier is present if an uppercase char is present."""
        var result = KeyEvent(self.code, self.modifiers, self.kind, self.state)
        if not self.code.isa[Char]():
            return result^

        var c = self.code[Char].char
        # if len(c) == 0:
        #     return result^

        # Get the first codepoint
        # Check if uppercase ASCII letter (A-Z: 65-90)
        if c.is_ascii_upper():
            result.modifiers.insert(KeyModifiers.SHIFT)
        elif result.modifiers.contains(KeyModifiers.SHIFT):
            # Convert to uppercase if shift is pressed (a-z: 97-122)
            var char_ord = c.to_u32()
            if char_ord >= 97 and char_ord <= 122:
                result.code = KeyCode(Char(char_ord - 32))  # a->A is -32
        return result^

    fn __eq__(self, other: Self) raises -> Bool:
        var lhs = self._normalize_case()
        var rhs = other._normalize_case()
        return (
            lhs.code == rhs.code and lhs.modifiers == rhs.modifiers and lhs.kind == rhs.kind and lhs.state == rhs.state
        )

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(
            "KeyEvent(code=",
            self.code,
            ", modifiers=",
            self.modifiers,
            ", kind=",
            self.kind,
            ", state=",
            self.state,
            ")",
        )

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Event Types (Focus, Paste, Resize)
# ============================================================================


@register_passable("trivial")
@fieldwise_init
struct FocusGained(EventType, ImplicitlyCopyable):
    """The terminal gained focus."""

    pass


@register_passable("trivial")
@fieldwise_init
struct FocusLost(EventType, ImplicitlyCopyable):
    """The terminal lost focus."""

    pass


@fieldwise_init
struct Paste(Copyable, EventType):
    """A string that was pasted into the terminal.

    Only emitted if bracketed paste has been enabled.
    """

    var content: String


@register_passable("trivial")
@fieldwise_init
struct Resize(EventType, ImplicitlyCopyable):
    """A resize event with new dimensions after resize (columns, rows).

    Note that resize events can occur in batches.
    """

    var columns: UInt16
    var rows: UInt16


# ============================================================================
# Event (main event type using Variant)
# ============================================================================


@fieldwise_init
struct Event(Copyable, InternalEventType, Stringable, Writable):
    """Represents an event.

    Events can be:
    - FocusGained: The terminal gained focus
    - FocusLost: The terminal lost focus
    - KeyEvent: A single key event with additional pressed modifiers
    - MouseEvent: A single mouse event with additional pressed modifiers
    - Paste: A string that was pasted (only if bracketed paste is enabled)
    - Resize: A resize event with new dimensions (columns, rows)
    """

    var value: Variant[FocusGained, FocusLost, KeyEvent, MouseEvent, Paste, Resize]

    @implicit
    fn __init__(out self, event: FocusGained):
        self.value = event

    @implicit
    fn __init__(out self, event: FocusLost):
        self.value = event

    @implicit
    fn __init__(out self, event: KeyEvent):
        self.value = event

    @implicit
    fn __init__(out self, event: MouseEvent):
        self.value = event

    @implicit
    fn __init__(out self, var event: Paste):
        self.value = event^

    @implicit
    fn __init__(out self, event: Resize):
        self.value = event

    fn write_to(self, mut writer: Some[Writer]):
        if self.value.isa[FocusGained]():
            writer.write(self.value[FocusGained])
        elif self.value.isa[FocusLost]():
            writer.write(self.value[FocusLost])
        elif self.value.isa[KeyEvent]():
            writer.write(self.value[KeyEvent])
        elif self.value.isa[MouseEvent]():
            writer.write(self.value[MouseEvent])
        elif self.value.isa[Paste]():
            writer.write(self.value[Paste])
        elif self.value.isa[Resize]():
            writer.write(self.value[Resize])
        else:
            writer.write("Unknown Event")

    fn __str__(self) -> String:
        return String.write(self)

    fn isa[T: EventType](self) -> Bool:
        """Checks if the value is of the given type.

        Parameters:
            T: The type to check against.

        Returns:
            True if the value is of the given type, False otherwise.
        """
        return self.value.isa[T]()

    fn __getitem__[T: EventType](ref self) -> ref[self.value] T:
        """Gets the value as the given type.

        Parameters:
            T: The type to get the value as.

        Returns:
            The value as the given type.
        """
        return self.value[T]

    fn is_key_press(self) -> Bool:
        """Returns True if this is a key press event.

        Returns False for key release and repeat events (as well as for non-key events).
        """
        if not self.value.isa[KeyEvent]():
            return False
        return self.value[KeyEvent].kind == KeyEventKind.Press

    fn is_key_release(self) -> Bool:
        """Returns True if this is a key release event."""
        if not self.value.isa[KeyEvent]():
            return False
        return self.value[KeyEvent].kind == KeyEventKind.Release

    fn is_key_repeat(self) -> Bool:
        """Returns True if this is a key repeat event."""
        if not self.value.isa[KeyEvent]():
            return False
        return self.value[KeyEvent].kind == KeyEventKind.Repeat

    fn as_key_event(self) -> Optional[KeyEvent]:
        """Returns the key event if this is a key event, otherwise None."""
        if self.value.isa[KeyEvent]():
            return self.value[KeyEvent]
        return None

    fn as_key_press_event(self) -> Optional[KeyEvent]:
        """Returns the KeyEvent if this is a key press event, otherwise None."""
        if self.is_key_press():
            return self.value[KeyEvent]
        return None

    fn as_key_release_event(self) -> Optional[KeyEvent]:
        """Returns the KeyEvent if this is a key release event, otherwise None."""
        if self.is_key_release():
            return self.value[KeyEvent]
        return None

    fn as_key_repeat_event(self) -> Optional[KeyEvent]:
        """Returns the KeyEvent if this is a key repeat event, otherwise None."""
        if self.is_key_repeat():
            return self.value[KeyEvent]
        return None

    fn as_mouse_event(self) -> Optional[MouseEvent]:
        """Returns the mouse event if this is a mouse event, otherwise None."""
        if self.value.isa[MouseEvent]():
            return self.value[MouseEvent]
        return None

    fn as_paste_event(self) -> Optional[String]:
        """Returns the pasted string if this is a paste event, otherwise None."""
        if self.value.isa[Paste]():
            return self.value[Paste].content
        return None

    fn as_resize_event(self) -> Optional[Tuple[UInt16, UInt16]]:
        """Returns the size as a tuple (columns, rows) if this is a resize event."""
        if self.value.isa[Resize]():
            ref r = self.value[Resize]
            return (r.columns, r.rows)
        return None
