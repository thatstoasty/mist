from utils.variant import Variant

from mist.event.event import Char, Event, InternalEventType, KeyboardEnhancementFlags


# ============================================================================
# Internal Event Types
# ============================================================================


@register_passable("trivial")
@fieldwise_init
struct CursorPosition(ImplicitlyCopyable, InternalEventType, Stringable, Writable):
    """A cursor position response (column, row)."""

    var column: UInt16
    var row: UInt16

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("CursorPosition(", self.column, ", ", self.row, ")")

    fn __str__(self) -> String:
        return String.write(self)


@register_passable("trivial")
@fieldwise_init
struct KeyboardEnhancementFlagsResponse(ImplicitlyCopyable, InternalEventType, Stringable, Writable):
    """The progressive keyboard enhancement flags enabled by the terminal."""

    var flags: KeyboardEnhancementFlags

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("KeyboardEnhancementFlagsResponse(", self.flags.bits(), ")")

    fn __str__(self) -> String:
        return String.write(self)


@register_passable("trivial")
@fieldwise_init
struct PrimaryDeviceAttributes(ImplicitlyCopyable, InternalEventType, Stringable, Writable):
    """Attributes and architectural class of the terminal.

    This is a stub - the response is not exposed in the public API.
    """

    var _placeholder: Bool
    """Placeholder field (compiler workaround for empty structs)."""

    fn __init__(out self):
        self._placeholder = True

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("PrimaryDeviceAttributes")

    fn __str__(self) -> String:
        return String.write(self)


# ============================================================================
# Internal Event
# ============================================================================


struct InternalEvent(Copyable, Stringable, Writable):
    """An internal event.

    Encapsulates publicly available Event with additional internal
    events that shouldn't be publicly available to the crate users.
    """

    var value: Variant[
        Event,
        CursorPosition,
        KeyboardEnhancementFlagsResponse,
        PrimaryDeviceAttributes,
    ]

    @implicit
    fn __init__(out self, var event: Event):
        self.value = event^

    @implicit
    fn __init__(out self, position: CursorPosition):
        self.value = position

    @implicit
    fn __init__(out self, flags: KeyboardEnhancementFlagsResponse):
        self.value = flags

    @implicit
    fn __init__(out self, attrs: PrimaryDeviceAttributes):
        self.value = attrs

    fn isa[T: InternalEventType](self) -> Bool:
        """Check if the internal event is of the specified type."""
        return self.value.isa[T]()

    fn __getitem__[T: InternalEventType](self) -> ref[self.value] T:
        """Get the internal event as the specified type (asserts the type)."""
        return self.value[T]

    fn is_event(self) -> Bool:
        """Check if this is a regular Event."""
        return self.value.isa[Event]()

    fn is_cursor_position(self) -> Bool:
        """Check if this is a CursorPosition response."""
        return self.value.isa[CursorPosition]()

    fn is_keyboard_enhancement_flags(self) -> Bool:
        """Check if this is a KeyboardEnhancementFlagsResponse."""
        return self.value.isa[KeyboardEnhancementFlagsResponse]()

    fn is_primary_device_attributes(self) -> Bool:
        """Check if this is a PrimaryDeviceAttributes response."""
        return self.value.isa[PrimaryDeviceAttributes]()

    fn as_event(ref self) -> ref[self.value] Event:
        """Get the Event (asserts this is an Event)."""
        return self.value[Event]

    fn as_cursor_position(ref self) -> ref[self.value] CursorPosition:
        """Get the CursorPosition (asserts this is a CursorPosition)."""
        return self.value[CursorPosition]

    fn as_keyboard_enhancement_flags(ref self) -> ref[self.value] KeyboardEnhancementFlagsResponse:
        """Get the KeyboardEnhancementFlagsResponse."""
        return self.value[KeyboardEnhancementFlagsResponse]

    fn as_primary_device_attributes(ref self) -> ref[self.value] PrimaryDeviceAttributes:
        """Get the PrimaryDeviceAttributes."""
        return self.value[PrimaryDeviceAttributes]

    fn write_to(self, mut writer: Some[Writer]):
        if self.value.isa[Event]():
            writer.write("InternalEvent::Event(", self.value[Event], ")")
        elif self.value.isa[CursorPosition]():
            writer.write("InternalEvent::CursorPosition(", self.value[CursorPosition], ")")
        elif self.value.isa[KeyboardEnhancementFlagsResponse]():
            writer.write(
                "InternalEvent::KeyboardEnhancementFlagsResponse(", self.value[KeyboardEnhancementFlagsResponse], ")"
            )
        elif self.value.isa[PrimaryDeviceAttributes]():
            writer.write("InternalEvent::PrimaryDeviceAttributes(", self.value[PrimaryDeviceAttributes], ")")
        else:
            writer.write("InternalEvent::Unknown")

    fn __str__(self) -> String:
        return String.write(self)
