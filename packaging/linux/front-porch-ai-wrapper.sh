#!/bin/bash
# Front Porch AI launcher wrapper.
#
# Sets up the library path for the bundled Flutter engine, then runs the
# real binary. Installed as /usr/bin/front-porch-ai by the .deb package.
#
# Known-harmless GTK warnings are filtered from stderr so CLI launches don't
# show users cryptic messages they can't act on. Real errors pass through
# untouched, and the binary's exit code is preserved.

set -u

APP_DIR="/opt/front-porch-ai"
export LD_LIBRARY_PATH="$APP_DIR/lib:${LD_LIBRARY_PATH:-}"

# GDK prints "Gdk-Message: ... Unable to load ... from the cursor theme" on
# systems with an incomplete cursor theme. Cosmetic — the app falls back to
# a default cursor. Filter that line; everything else on stderr is shown.
"$APP_DIR/front_porch_ai" "$@" 2> >(grep -v "from the cursor theme" >&2)
exit_code=$?
exit $exit_code
