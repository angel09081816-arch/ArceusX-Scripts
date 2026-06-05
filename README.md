# Flicker Role Viewer

This copy is a fresh rewrite for Roblox / Arceus X.

## Install
Paste this into Arceus X and run it:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/angel09081816-arch/ArceusX-Scripts/main/Flicker_Role_Viewer.lua"))()
```

## What changed
- Rebuilt the viewer from scratch for a cleaner Flicker-style UI.
- Added a reliable floating toggle button and touch-friendly panel.
- Added role-name color rules:
  - Detective / Savior / Guardian = blue
  - Murderer / Killer / Evil / Cult = red
  - Clown = grey
- Keeps the viewer client-side first, with an optional server helper if you want richer role data.

## Optional server helper
If you want extra server-only role hints, place `Flicker_Role_Viewer_Server.lua` into `ServerScriptService` in Roblox Studio and run the game once.

## Notes
- The viewer only shows values the client can actually read.
- If the game hides role data in server-only objects, the panel will show a safe empty state instead of fake data.
