# Server Edition — `kavi/server-edition`

The server variant of the Front Porch AI front-end revamp. Branched from
`kavi/gui-revamp` (the individual/desktop edition); the two share the full
UI and design language, and the server edition adds multi-user server
behavior on top.

**Live interactive preview (shared design):**
https://muse.ai/s/front-porch-gui-preview-xpxk61rlo1xvxuxj

## What makes it the server edition

- **User accounts on the server.** Each login spins up a per-user session
  slice: their character card, context slot, and queued generations.
- **Logout hands everything back.** The slice is torn down on logout; when
  the last active user logs out, the engines fully unload — the server idles
  at near-zero overhead. It only works as hard as whoever's using it.
- **Remote access from anywhere.** Tailscale-first: the app sets up the
  tunnel itself, the phone installs the Tailscale app once, and it works on
  any cell signal or hotspot. Pairing is click-and-connect — one button, one
  QR code, no IP addresses or ports ever shown. Password + 2FA stay
  user-facing.
- **Same creativity-first UI** as the individual edition: creator boards,
  Kardashev system, content zones, Dead Dove negotiated limits, Engine
  resources with real queueing and VRAM arbitration.

## Status

In development. Engine-resource wiring (generation queue, dual-engine VRAM
arbitration, session-scoped teardown) lands here from the individual branch.
