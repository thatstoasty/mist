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
    pass


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
    """The value of the internal event, which can be one of the following types:
        - Event: A regular event.
        - CursorPosition: A response to a cursor position query.
        - KeyboardEnhancementFlagsResponse: A response to a keyboard enhancement flags query.
        - PrimaryDeviceAttributes: A response to a primary device attributes query.
    """

    @implicit
    def __init__(out self, var event: Event):
        self.value = event^

    @implicit
    def __init__(out self, position: CursorPosition):
        self.value = position

    @implicit
    def __init__(out self, flags: KeyboardEnhancementFlagsResponse):
        self.value = flags

    @implicit
    def __init__(out self, attrs: PrimaryDeviceAttributes):
        self.value = attrs

    def isa[T: InternalEventType](self) -> Bool:
        """Check if the internal event is of the specified type."""
        return self.value.isa[T]()

    def __getitem_param__[T: InternalEventType](self) -> ref[self.value] T:
        """Get the internal event as the specified type (asserts the type)."""
        return self.value[T]

    def is_event(self) -> Bool:
        """Check if this is a regular Event."""
        return self.value.isa[Event]()

    def is_cursor_position(self) -> Bool:
        """Check if this is a CursorPosition response."""
        return self.value.isa[CursorPosition]()

    def is_keyboard_enhancement_flags(self) -> Bool:
        """Check if this is a KeyboardEnhancementFlagsResponse."""
        return self.value.isa[KeyboardEnhancementFlagsResponse]()

    def is_primary_device_attributes(self) -> Bool:
        """Check if this is a PrimaryDeviceAttributes response."""
        return self.value.isa[PrimaryDeviceAttributes]()

    def as_event(ref self) -> ref[self.value] Event:
        """Get the Event (asserts this is an Event)."""
        return self.value[Event]

    def as_cursor_position(ref self) -> ref[self.value] CursorPosition:
        """Get the CursorPosition (asserts this is a CursorPosition)."""
        return self.value[CursorPosition]

    def as_keyboard_enhancement_flags(ref self) -> ref[self.value] KeyboardEnhancementFlagsResponse:
        """Get the KeyboardEnhancementFlagsResponse."""
        return self.value[KeyboardEnhancementFlagsResponse]

    def as_primary_device_attributes(ref self) -> ref[self.value] PrimaryDeviceAttributes:
        """Get the PrimaryDeviceAttributes."""
        return self.value[PrimaryDeviceAttributes]

    def write_to(self, mut writer: Some[Writer]):
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

    def write_repr_to(self, mut writer: Some[Writer]):
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
