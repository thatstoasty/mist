from std.testing import TestSuite

from std import sys

from mist.multiplex.event import Event
from mist.multiplex.kqueue import KQueueSelector


def test_kqueue_selector_lifecycle() raises -> None:
    """Exercise the basic lifecycle of the kqueue selector.

    Raises:
        Error: If selector creation, registration, polling, unregistration, or
            teardown fails.
    """
    var selector = KQueueSelector()
    selector.register(sys.stdin, Event.READ)
    _ = selector.select(0)
    selector.unregister(sys.stdin, Event.READ)
    selector.close()


def main() raises:
    """Run the kqueue selector smoke tests.

    Raises:
        Error: If the test suite encounters a failing assertion or runtime error.
    """
    TestSuite.discover_tests[__functions_in_module()]().run()
