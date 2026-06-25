"""Internal event types used by the parser, not exposed in the public API."""
from std.utils.variant import Variant

from mist.event.event import Char, Event, InternalEventType, KeyboardEnhancementFlags


# ============================================================================
# Internal Event Types
# ============================================================================


@fieldwise_init
struct CursorPosition(ImplicitlyCopyable, InternalEventType, TrivialRegisterPassable, Writable):
    """A cursor position response (column, row)."""

    var column: UInt16
    """The cursor column position (0-based)."""
    var row: UInt16
    """The cursor row position (0-based)."""


@fieldwise_init
struct KeyboardEnhancementFlagsResponse(ImplicitlyCopyable, InternalEventType, TrivialRegisterPassable, Writable):
    """The progressive keyboard enhancement flags enabled by the terminal."""

    var flags: KeyboardEnhancementFlags
    """The progressive keyboard enhancement flags enabled by the terminal."""


@fieldwise_init
struct PrimaryDeviceAttributes(ImplicitlyCopyable, InternalEventType, TrivialRegisterPassable, Writable):
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
        """Wraps a regular public `Event` as an `InternalEvent`.

        Args:
            event: The event to wrap.
        """
        self.value = event^

    @implicit
    def __init__(out self, position: CursorPosition):
        """Wraps a `CursorPosition` response as an `InternalEvent`.

        Args:
            position: The cursor position response to wrap.
        """
        self.value = position

    @implicit
    def __init__(out self, flags: KeyboardEnhancementFlagsResponse):
        """Wraps a `KeyboardEnhancementFlagsResponse` as an `InternalEvent`.

        Args:
            flags: The keyboard enhancement flags response to wrap.
        """
        self.value = flags

    @implicit
    def __init__(out self, attrs: PrimaryDeviceAttributes):
        """Wraps `PrimaryDeviceAttributes` as an `InternalEvent`.

        Args:
            attrs: The primary device attributes response to wrap.
        """
        self.value = attrs

    def isa[T: InternalEventType](self) -> Bool:
        """Check if the internal event is of the specified type.

        Parameters:
            T: The internal event type to check against.

        Returns:
            True if the internal event holds a value of type `T`, False otherwise.
        """
        return self.value.isa[T]()

    def __getitem_param__[T: InternalEventType](self) -> ref[self.value] T:
        """Get the internal event as the specified type (asserts the type).

        Parameters:
            T: The internal event type to retrieve.

        Returns:
            A reference to the wrapped value as type `T`.
        """
        return self.value[T]

    def is_event(self) -> Bool:
        """Check if this is a regular Event.

        Returns:
            True if the wrapped value is an `Event`, False otherwise.
        """
        return self.value.isa[Event]()

    def is_cursor_position(self) -> Bool:
        """Check if this is a CursorPosition response.

        Returns:
            True if the wrapped value is a `CursorPosition`, False otherwise.
        """
        return self.value.isa[CursorPosition]()

    def is_keyboard_enhancement_flags(self) -> Bool:
        """Check if this is a KeyboardEnhancementFlagsResponse.

        Returns:
            True if the wrapped value is a `KeyboardEnhancementFlagsResponse`, False otherwise.
        """
        return self.value.isa[KeyboardEnhancementFlagsResponse]()

    def is_primary_device_attributes(self) -> Bool:
        """Check if this is a PrimaryDeviceAttributes response.

        Returns:
            True if the wrapped value is `PrimaryDeviceAttributes`, False otherwise.
        """
        return self.value.isa[PrimaryDeviceAttributes]()

    def as_event(ref self) -> ref[self.value] Event:
        """Get the Event (asserts this is an Event).

        Returns:
            A reference to the wrapped `Event`.
        """
        return self.value[Event]

    def as_cursor_position(ref self) -> ref[self.value] CursorPosition:
        """Get the CursorPosition (asserts this is a CursorPosition).

        Returns:
            A reference to the wrapped `CursorPosition`.
        """
        return self.value[CursorPosition]

    def as_keyboard_enhancement_flags(ref self) -> ref[self.value] KeyboardEnhancementFlagsResponse:
        """Get the KeyboardEnhancementFlagsResponse.

        Returns:
            A reference to the wrapped `KeyboardEnhancementFlagsResponse`.
        """
        return self.value[KeyboardEnhancementFlagsResponse]

    def as_primary_device_attributes(ref self) -> ref[self.value] PrimaryDeviceAttributes:
        """Get the PrimaryDeviceAttributes.

        Returns:
            A reference to the wrapped `PrimaryDeviceAttributes`.
        """
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
