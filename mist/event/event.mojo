"""Event module for terminal input handling.

This module provides functionality to read keyboard, mouse, and terminal resize events.
It includes types for representing various input events and their properties.

**Important:** Make sure to enable raw mode for keyboard events to work properly.

## Mouse and Focus Events

Mouse and focus events are not enabled by default. You have to enable them with
the EnableMouseCapture / EnableFocusChange commands.
"""

from std.utils import Variant


# ============================================================================
# Keyboard Enhancement Flags (bitflags)
# ============================================================================


struct KeyboardEnhancementFlags(Equatable, Writable, ImplicitlyCopyable, TrivialRegisterPassable):
    """Represents special flags that tell compatible terminals to add extra information to keyboard events.

    See https://sw.kovidgoyal.net/kitty/keyboard-protocol/#progressive-enhancement for more information.
    """

    var value: UInt8
    """The raw bits representing the enabled keyboard enhancement flags."""

    comptime DISAMBIGUATE_ESCAPE_CODES = KeyboardEnhancementFlags(0b0000_0001)
    """Represent Escape and modified keys using CSI-u sequences, so they can be unambiguously read."""
    comptime REPORT_EVENT_TYPES = KeyboardEnhancementFlags(0b0000_0010)
    """Add extra events with KeyEvent.kind set to KeyEventKind::Repeat or KeyEventKind::Release
    when keys are autorepeated or released."""
    comptime REPORT_ALTERNATE_KEYS = KeyboardEnhancementFlags(0b0000_0100)
    """Send alternate keycodes in addition to the base keycode."""
    comptime REPORT_ALL_KEYS_AS_ESCAPE_CODES = KeyboardEnhancementFlags(0b0000_1000)
    """Represent all keyboard events as CSI-u sequences."""

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
struct KeyModifiers(Equatable, ImplicitlyCopyable, Writable, TrivialRegisterPassable):
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

# ============================================================================
# Key Event State (bitflags)
# ============================================================================


@fieldwise_init
struct KeyEventState(Equatable, ImplicitlyCopyable, Writable, TrivialRegisterPassable):
    """Represents extra state about the key event.

    Note: This state can only be read if
    KeyboardEnhancementFlags.DISAMBIGUATE_ESCAPE_CODES has been enabled.
    """

    var value: UInt8
    """The raw bits representing the key event state."""

    comptime NONE = KeyEventState(0b0000_0000)
    """The key event origins from the keypad."""
    comptime KEYPAD = KeyEventState(0b0000_0001)
    """Caps Lock was enabled for this key event."""
    comptime CAPS_LOCK = KeyEventState(0b0000_0010)
    """Num Lock was enabled for this key event."""
    comptime NUM_LOCK = KeyEventState(0b0000_0100)
    """The key event was generated by auto-repeat."""

    fn __or__(self, other: Self) -> Self:
        return Self(self.value | other.value)

    fn __and__(self, other: Self) -> Self:
        return Self(self.value & other.value)

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        """Format the key event state joined by a '+' character.

        Args:
            writer: The writer to write the formatted key event state to.
        """
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

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the key event state to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        writer.write("KeyEventState(", self.value, ")")

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
struct KeyEventKind(Equatable, ImplicitlyCopyable, Writable, TrivialRegisterPassable):
    """Represents a keyboard event kind."""

    var value: UInt8
    """The specific kind of key event."""

    comptime Press = KeyEventKind(0)
    """Event for key press."""
    comptime Repeat = KeyEventKind(1)
    """Event for key auto-repeat."""
    comptime Release = KeyEventKind(2)
    """Event for key release."""

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        if self == Self.Press:
            writer.write("Press")
        elif self == Self.Repeat:
            writer.write("Repeat")
        else:
            writer.write("Release")

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the key event kind to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        writer.write("KeyEventKind(", self.value, ")")


# ============================================================================
# Media Key Code (using struct constants since no enums)
# ============================================================================


@fieldwise_init
struct MediaKeyCode(Equatable, ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents a media key."""

    var value: UInt8
    """The specific media key code."""

    comptime Play = MediaKeyCode(0)
    """Play."""
    comptime Pause = MediaKeyCode(1)
    """Pause."""
    comptime PlayPause = MediaKeyCode(2)
    """Play/Pause."""
    comptime Reverse = MediaKeyCode(3)
    """Reverse."""
    comptime Stop = MediaKeyCode(4)
    """Stop."""
    comptime FastForward = MediaKeyCode(5)
    """Fast Forward."""
    comptime Rewind = MediaKeyCode(6)
    """Rewind."""
    comptime TrackNext = MediaKeyCode(7)
    """Next Track."""
    comptime TrackPrevious = MediaKeyCode(8)
    """Previous Track."""
    comptime Record = MediaKeyCode(9)
    """Record."""
    comptime LowerVolume = MediaKeyCode(10)
    """Lower Volume."""
    comptime RaiseVolume = MediaKeyCode(11)
    """Raise Volume."""
    comptime MuteVolume = MediaKeyCode(12)
    """Mute Volume."""

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

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the media key code to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        writer.write("MediaKeyCode(", self.value, ")")


# ============================================================================
# Modifier Key Code (using struct constants since no enums)
# ============================================================================


@fieldwise_init
struct ModifierKeyCode(Equatable, ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents a modifier key.

    On macOS, control is "Control", alt is "Option", and super is "Command".
    """

    var value: UInt8
    """The specific modifier key code."""

    comptime LeftShift = ModifierKeyCode(0)
    """Left Shift."""
    comptime LeftControl = ModifierKeyCode(1)
    """Left Control."""
    comptime LeftAlt = ModifierKeyCode(2)
    """Left Option."""
    comptime LeftSuper = ModifierKeyCode(3)
    """Left Command."""
    comptime LeftHyper = ModifierKeyCode(4)
    """Left Hyper."""
    comptime LeftMeta = ModifierKeyCode(5)
    """Left Meta."""
    comptime RightShift = ModifierKeyCode(6)
    """Right Shift."""
    comptime RightControl = ModifierKeyCode(7)
    """Right Control."""
    comptime RightAlt = ModifierKeyCode(8)
    """Right Option."""
    comptime RightSuper = ModifierKeyCode(9)
    """Right Command."""
    comptime RightHyper = ModifierKeyCode(10)
    """Right Hyper."""
    comptime RightMeta = ModifierKeyCode(11)
    """Right Meta."""
    comptime IsoLevel3Shift = ModifierKeyCode(12)
    """Iso Level 3 Shift."""
    comptime IsoLevel5Shift = ModifierKeyCode(13)
    """Iso Level 5 Shift."""

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        """Format the modifier key (macOS style).

        Args:
            writer: The writer to write the formatted modifier key to.
        """
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

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the modifier key code to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        writer.write("ModifierKeyCode(", self.value, ")")


# ============================================================================
# Key Code
# ============================================================================


trait KeyType(Writable, Equatable):
    """Marker trait for key types."""

    pass


@fieldwise_init
struct Backspace(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Backspace key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Enter(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Enter key."""

    fn __eq__(self, other: Self) -> Bool:
        return True

@fieldwise_init
struct Left(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Left key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Right(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Right key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Up(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Up key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Down(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Down key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Home(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Home key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct End(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the End key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct PageUp(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Page Up key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct PageDown(ImplicitlyCopyable, KeyType):
    """Represents the Page Down key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Tab(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Tab key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct BackTab(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Back Tab key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Delete(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Delete key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Insert(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Insert key."""

    fn __eq__(self, other: Self) -> Bool:
        return True



@fieldwise_init
struct Null(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents a Null key event."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Esc(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Escape key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct CapsLock(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Caps Lock key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct ScrollLock(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Scroll Lock key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct NumLock(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Num Lock key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct PrintScreen(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Print Screen key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Pause(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Pause key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Menu(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the Menu key."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct KeypadBegin(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents the beginning of the keypad keys.

    This is used to indicate that subsequent keys are from the keypad, and is only sent if
    `KeyboardEnhancementFlags.KEYPAD` is enabled.
    """

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct FunctionKey(ImplicitlyCopyable, KeyType, TrivialRegisterPassable):
    """Represents a function key (F1-F12)."""
    var number: UInt8
    """Represents a function key (F1-F12). The number field indicates which function key it is (1 for F1, 2 for F2, etc.)."""

    fn write_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the key code to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        writer.write("F", self.number)

    fn __eq__(self, other: Self) -> Bool:
        return self.number == other.number


@fieldwise_init
struct Char(Equatable, ImplicitlyCopyable, KeyType):
    """Represents a character key."""
    var char: Codepoint
    """The character represented by this key code."""

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
        """Writes the character to the given writer.

        Args:
            writer: The writer to write the character to.
        """
        writer.write(self.char)

    fn __eq__(self, other: Self) -> Bool:
        return self.char == other.char

    fn __eq__(self, other: StringSlice) -> Bool:
        return self.char == Codepoint.ord(other)


@fieldwise_init
struct KeyCode(Equatable, ImplicitlyCopyable, Writable):
    """Represents a key.

    This struct uses a type tag and a value field to represent different key types.
    Use the static methods to create specific key codes.
    """

    comptime _type = Variant[
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
    var value: Self._type
    """Internal value of the key code, which can be one of several types representing different keys."""

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

    fn is_same_type(self, other: Self) -> Bool:
        """Returns True if self and other have the same key type.

        Args:
            other: The other KeyCode to compare with.

        Returns:
            True if self and other have the same key type, False otherwise.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            if self.value.isa[type]() and other.value.isa[type]():
                return True
        return False

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other are the same key code (same type and value).

        Args:
            other: The other KeyCode to compare with.

        Returns:
            True if self and other are the same key code, False otherwise.
        """
        # Traverse Variant types via loop instead of checking each type manually.
        # We make sure it implements equatable, then downcast for the comparison.
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            if not self.value.isa[type]() or not other.value.isa[type]():
                continue

            comptime assert conforms_to(type, Equatable), String(t"KeyCode type at index, {i}, must implement Equatable for equality comparison")
            ref left = trait_downcast[Equatable](self.value[type])
            ref right = trait_downcast[Equatable](other.value[type])
            if left == right:
                return True

        return False

    fn isa[T: KeyType](self) -> Bool:
        """Returns True if the key code is of type T."""
        return self.value.isa[T]()

    fn __getitem_param__[T: KeyType](ref self) -> ref[self.value] T:
        """Returns the key code as type T."""
        return self.value[T]

    fn write_to(self, mut writer: Some[Writer]) -> None:
        """Writes the KeyCode to the writer.

        On macOS, Backspace is "Delete", Delete is "Fwd Del", and Enter is "Return".

        Args:
            writer: The writer to write the key code to.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            if self.value.isa[type]():
                comptime assert conforms_to(type, Writable), String(t"KeyCode type at index, {i}, must implement Writable for formatting")
                return trait_downcast[Writable](self.value[type]).write_to(writer)

    fn write_repr_to(self, mut writer: Some[Writer]) -> None:
        """Writes the KeyCode to the writer.

        On macOS, Backspace is "Delete", Delete is "Fwd Del", and Enter is "Return".

        Args:
            writer: The writer to write the KeyCode representation to.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            if self.value.isa[type]():
                comptime assert conforms_to(type, Writable), String(t"KeyCode type at index, {i}, must implement Writable for formatting")
                return trait_downcast[Writable](self.value[type]).write_repr_to(writer)


# ============================================================================
# Mouse Button
# ============================================================================


@fieldwise_init
struct MouseButton(Equatable, ImplicitlyCopyable, Writable, TrivialRegisterPassable):
    """Represents a mouse button."""

    var value: UInt8
    """The specific mouse button code."""

    comptime Left = MouseButton(0)
    """Left mouse button."""
    comptime Right = MouseButton(1)
    """Right mouse button."""
    comptime Middle = MouseButton(2)
    """Middle mouse button."""

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn write_to(self, mut writer: Some[Writer]):
        if self == Self.Left:
            writer.write("Left")
        elif self == Self.Right:
            writer.write("Right")
        else:
            writer.write("Middle")


# ============================================================================
# Mouse Event Kind (using Variant since it can carry data)
# ============================================================================


trait MouseEventType(Writable, Equatable):
    """Marker trait for mouse event types."""

    ...


@fieldwise_init
struct MousePress(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Pressed mouse button."""

    var button: MouseButton
    """The mouse button that was pressed."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MousePress event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return self.button == other.button


@fieldwise_init
struct MouseRelease(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Released mouse button."""

    var button: MouseButton
    """The mouse button that was released."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MousePress event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return self.button == other.button


@fieldwise_init
struct MouseDrag(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Moved the mouse cursor while pressing a button."""

    var button: MouseButton
    """The mouse button that is being pressed while dragging."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MousePress event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return self.button == other.button


@fieldwise_init
struct MouseMoved(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Moved the mouse cursor while not pressing a mouse button."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MouseMoved event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return True


@fieldwise_init
struct MouseScrollDown(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Scrolled mouse wheel downwards (towards the user)."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MouseMoved event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return True


@fieldwise_init
struct MouseScrollUp(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Scrolled mouse wheel upwards (away from the user)."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MouseMoved event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return True


@fieldwise_init
struct MouseScrollLeft(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Scrolled mouse wheel left (mostly on a laptop touchpad)."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MouseMoved event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return True


@fieldwise_init
struct MouseScrollRight(Equatable, ImplicitlyCopyable, MouseEventType, TrivialRegisterPassable):
    """Scrolled mouse wheel right (mostly on a laptop touchpad)."""

    fn __eq__(self, other: Self) -> Bool:
        """Returns True if self and other represent the same mouse button event.

        Args:
            other: The other MouseMoved event to compare with.

        Returns:
            True if self and other represent the same mouse button event, False otherwise.
        """
        return True


# ============================================================================
# Mouse Event
# ============================================================================


struct MouseEventKind(ImplicitlyCopyable, Writable):
    comptime _type = Variant[
        MousePress,
        MouseRelease,
        MouseDrag,
        MouseMoved,
        MouseScrollDown,
        MouseScrollUp,
        MouseScrollLeft,
        MouseScrollRight,
    ]
    """Represents the kind of mouse event that occurred."""
    var event: Self._type
    """Internal value of the mouse event kind, which can be one of several types representing different mouse events."""

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

    fn __getitem_param__[T: MouseEventType](ref self) -> ref[self.event] T:
        """Returns the mouse event kind as type T."""
        return self.event[T]

    fn write_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            comptime assert conforms_to(type, Writable), String(t"Type at index, {i}, must implement Writable.")
            if self.event.isa[type]():
                writer.write(trait_downcast[Writable](self.event[type]))
                return

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            comptime assert conforms_to(type, Writable), String(t"Type at index, {i}, must implement Writable.")
            if self.event.isa[type]():
                trait_downcast[Writable](self.event[type]).write_repr_to(writer)
                return


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

# ============================================================================
# Key Event
# ============================================================================


trait InternalEventType(Writable, Equatable):
    """Marker trait for internal event types."""

    pass


trait EventType(Writable, Equatable):
    """Event Type marker trait."""

    pass


@fieldwise_init
struct KeyEvent(Equatable, EventType, ImplicitlyCopyable, Writable):
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
        """Create a new KeyEvent with specified kind and empty state.

        Args:
            code: The key code of the event.
            modifiers: The key modifiers active during the event.
            kind: The kind of key event (Press, Repeat, Release). Defaults to Press.
        """
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
        """Writes a string representation of the key event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        # TODO: Find a better way than allocating another string.
        if self.code.isa[Char]() and self.modifiers.contains(KeyModifiers.SHIFT):
            var temp = String.write(self.code)
            writer.write(temp.upper())
            return

        self.code.write_to(writer)
        if self.modifiers != KeyModifiers.NONE:
            writer.write(" + ", self.modifiers)
        if self.kind != KeyEventKind.Press:
            writer.write(" (", self.kind, ")")
        if self.state != KeyEventState.NONE:
            writer.write(" [", self.state, "]")


# ============================================================================
# Event Types (Focus, Paste, Resize)
# ============================================================================


@fieldwise_init
struct FocusGained(EventType, ImplicitlyCopyable, TrivialRegisterPassable):
    """The terminal gained focus."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct FocusLost(EventType, ImplicitlyCopyable, TrivialRegisterPassable):
    """The terminal lost focus."""

    fn __eq__(self, other: Self) -> Bool:
        return True


@fieldwise_init
struct Paste(Copyable, EventType):
    """A string that was pasted into the terminal.

    Only emitted if bracketed paste has been enabled.
    """

    var content: String
    """The string that was pasted."""


@fieldwise_init
struct Resize(EventType, ImplicitlyCopyable, TrivialRegisterPassable):
    """A resize event with new dimensions after resize (columns, rows).

    Note that resize events can occur in batches.
    """

    var columns: UInt16
    """Number of columns after the resize event."""
    var rows: UInt16
    """Number of rows after the resize event."""


# ============================================================================
# Event (main event type using Variant)
# ============================================================================


@fieldwise_init
struct Event(Copyable, InternalEventType, Writable):
    """Represents an event.

    Events can be:
    - FocusGained: The terminal gained focus
    - FocusLost: The terminal lost focus
    - KeyEvent: A single key event with additional pressed modifiers
    - MouseEvent: A single mouse event with additional pressed modifiers
    - Paste: A string that was pasted (only if bracketed paste is enabled)
    - Resize: A resize event with new dimensions (columns, rows)
    """

    comptime _type = Variant[FocusGained, FocusLost, KeyEvent, MouseEvent, Paste, Resize]
    """Internal type variant."""
    var value: Self._type
    """Internal value of the event, which can be one of several types representing different events."""

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
        """Writes a string representation of the event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            comptime assert conforms_to(type, Writable), String(t"Type at index, {i}, must implement Writable.")
            if self.value.isa[type]():
                trait_downcast[Writable](self.value[type]).write_to(writer)
                return

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        comptime for i in range(Variadic.size(Self._type.Ts)):
            comptime type = Self._type.Ts[i]
            comptime assert conforms_to(type, Writable), String(t"Type at index, {i}, must implement Writable.")
            if self.value.isa[type]():
                trait_downcast[Writable](self.value[type]).write_repr_to(writer)
                return

    fn isa[T: EventType](self) -> Bool:
        """Checks if the value is of the given type.

        Parameters:
            T: The type to check against.

        Returns:
            True if the value is of the given type, False otherwise.
        """
        return self.value.isa[T]()

    fn __getitem_param__[T: EventType](ref self) -> ref[self.value] T:
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
