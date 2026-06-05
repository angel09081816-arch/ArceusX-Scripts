# Flicker Role Viewer for Arceus X

This folder now contains a fully client-side role viewer for Roblox / Arceus X, designed to work from Arceus X alone with no Studio script required.

## Mobile setup guide
1. Open Arceus X and paste this loadstring into the executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/angel09081816-arch/ArceusX-Scripts/main/Flicker_Role_Viewer.lua"))()
```

2. Tap Execute. The viewer now creates a guaranteed floating panel and a visible blue Open Viewer button at the bottom-right corner.
3. If the panel is hidden, tap the blue button again to reopen it. On mobile, the panel is sized for touch and uses a simpler layout.
4. Use the tabs at the top to switch between Overview, Players, and Chats.
5. No Studio script is required. Everything runs from Arceus X and uses live local scanning plus chat capture.
6. If you still want extra server-side data, the optional helper in `Flicker_Role_Viewer_Server.lua` can be added later, but it is not required for the viewer to launch.

## Why the viewer may look empty
- The script only reads values the client can see. If the game keeps role data inside hidden server-only objects, no client script can reveal them reliably.
- Some games do not expose role, rank, team, faction, or journal values at all, so the viewer will show a friendly empty state instead of fake data.
- The UI is intentionally simple and mobile-friendly so it does not rely on fragile drag logic.

## What changed
- Rebuilt the viewer from scratch to remove the old fragile UI path.
- Added live chat capture with both chat service and player chat fallback.
- Kept the scan client-side, safe, and fully automated.
- Removed the need for any Studio-side setup to use the main viewer.

## What to put on GitHub
Upload this exact file to a public GitHub repository:

- Flicker_Role_Viewer.lua

The raw GitHub URL for this repository is:

https://raw.githubusercontent.com/angel09081816-arch/ArceusX-Scripts/main/Flicker_Role_Viewer.lua

## Quick mobile install
Paste this into Arceus X and run it:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/angel09081816-arch/ArceusX-Scripts/main/Flicker_Role_Viewer.lua"))()
```

## What the viewer does now
- Creates a small, touch-friendly floating panel that is easy to open and close.
- Uses a safe fallback GUI parent so the button and panel show up reliably in executors.
- Scans the local player and nearby player data for role/rank/team/faction/title and journal-like values when the game exposes them.
- Captures live chat and ghost/whisper-style messages when the game sends them to the client.
- Uses large touch-friendly buttons and simple tabs for mobile use.
- Refreshes every second so the list updates while you play.

## Optional server helper
If you want extra data from the server, place `Flicker_Role_Viewer_Server.lua` into `ServerScriptService` in Roblox Studio and run the game once. The client viewer will use it automatically when it is available.

## Important note
This script only reads values that are visible to the client. If the game stores the data in hidden server-only objects, no client-side script can reveal it reliably.

## Verification
The rebuilt viewer is intentionally simple, client-side first, and avoids the older fragile UI path that was causing the panel to fail to show up.
