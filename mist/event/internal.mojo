from std.utils.variant import Variant

from mist.event.event import Char, Event, InternalEventType, KeyboardEnhancementFlags


# ============================================================================
# Internal Event Types
# ============================================================================


@fieldwise_init
struct CursorPosition(ImplicitlyCopyable, InternalEventType, Writable, TrivialRegisterPassable):
    """A cursor position response (column, row)."""

    var column: UInt16
    """The cursor column position (0-based)."""
    var row: UInt16
    """The cursor row position (0-based)."""


@fieldwise_init
struct KeyboardEnhancementFlagsResponse(ImplicitlyCopyable, InternalEventType, Writable, TrivialRegisterPassable):
    """The progressive keyboard enhancement flags enabled by the terminal."""

    var flags: KeyboardEnhancementFlags
    """The progressive keyboard enhancement flags enabled by the terminal."""


@fieldwise_init
struct PrimaryDeviceAttributes(ImplicitlyCopyable, InternalEventType, Writable, TrivialRegisterPassable):
    """Attributes and architectural class of the terminal.

    This is a stub - the response is not exposed in the public API.
    """

    var _placeholder: Bool
    """Placeholder field (compiler workaround for empty structs)."""

    fn __init__(out self):
        self._placeholder = True


# ============================================================================
# Internal Event
# ============================================================================


struct InternalEvent(Copyable, Writable):
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

    fn __getitem_param__[T: InternalEventType](self) -> ref[self.value] T:
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
        """Writes a string representation of the internal event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        if self.value.isa[Event]():
            writer.write(t"InternalEvent(Event({self.value[Event]})")
        elif self.value.isa[CursorPosition]():
            writer.write(t"InternalEvent(CursorPosition({self.value[CursorPosition]}))")
        elif self.value.isa[KeyboardEnhancementFlagsResponse]():
            writer.write(
                t"InternalEvent(KeyboardEnhancementFlagsResponse({self.value[KeyboardEnhancementFlagsResponse]}))"
            )
        elif self.value.isa[PrimaryDeviceAttributes]():
            writer.write(t"InternalEvent(PrimaryDeviceAttributes({self.value[PrimaryDeviceAttributes]}))")
        else:
            writer.write("InternalEvent(value=UNKNOWN)")

    fn write_repr_to(self, mut writer: Some[Writer]):
        """Writes a string representation of the internal event to the given writer.

        Args:
            writer: The writer to write the string representation to.
        """
        if self.value.isa[Event]():
            writer.write(t"InternalEvent(value=Event({self.value[Event]})")
        elif self.value.isa[CursorPosition]():
            writer.write(t"InternalEvent(value=CursorPosition({self.value[CursorPosition]}))")
        elif self.value.isa[KeyboardEnhancementFlagsResponse]():
            writer.write(
                t"InternalEvent(value=KeyboardEnhancementFlagsResponse({self.value[KeyboardEnhancementFlagsResponse]}))"
            )
        elif self.value.isa[PrimaryDeviceAttributes]():
            writer.write(t"InternalEvent(value=PrimaryDeviceAttributes({self.value[PrimaryDeviceAttributes]}))")
        else:
            writer.write("InternalEvent(value=UNKNOWN)")
