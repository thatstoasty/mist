from mist.screen import set_window_title, set_foreground_color, set_background_color, set_cursor_color, hide_cursor, show_cursor
from mist.profile import Profile

fn main() raises:
    let title = "Example Title"
    let profile = Profile("TrueColor")
    let color = profile.color("#c9a0dc")

    # set_window_title sets the terminal window title
    set_window_title(title)

    # set_foreground_color sets the default foreground color
    set_foreground_color(color)

    # set_background_color sets the default background color
    set_background_color(color)

    # set_cursor_color sets the cursor color
    set_cursor_color(color)

    # # Hide the cursor
    # hide_cursor()

    # # Show the cursor
    # show_cursor()

# from mist.screen import enable_mouse_press, disable_mouse_press, enable_mouse, disable_mouse, enable_mouse_hilite, disable_mouse_hilite, enable_mouse_cell_motion, disable_mouse_cell_motion, enable_mouse_all_motion, disable_mouse_all_motion

# fn main() raises:
#     # Enable X10 mouse mode, only button press events are sent
#     enable_mouse_press()

#     # Disable X10 mouse mode
#     disable_mouse_press()

#     # Enable Mouse Tracking mode
#     enable_mouse()

#     # Disable Mouse Tracking mode
#     disable_mouse()

#     # Enable Hilite Mouse Tracking mode
#     enable_mouse_hilite()

#     # Disable Hilite Mouse Tracking mode
#     disable_mouse_hilite()

#     # Enable Cell Motion Mouse Tracking mode
#     enable_mouse_cell_motion()

#     # Disable Cell Motion Mouse Tracking mode
#     disable_mouse_cell_motion()

#     # Enable All Motion Mouse mode
#     enable_mouse_all_motion()

#     # Disable All Motion Mouse mode
#     disable_mouse_all_motion()
