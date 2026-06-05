# Flicker Role Viewer for Arceus X

This folder contains a fixed, client-side role viewer script for Roblox / Arceus X, plus an optional server helper for richer data.

## What to put on GitHub
Upload this exact file to a public GitHub repository:

- Flicker_Role_Viewer.lua

The raw GitHub URL for this repository is:

https://raw.githubusercontent.com/angel09081816-arch/ArceusX-Scripts/main/Flicker_Role_Viewer.lua

## Arceus X loadstring
Paste this into Arceus X:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/angel09081816-arch/ArceusX-Scripts/main/Flicker_Role_Viewer.lua"))()
```

## How to install it in Arceus X
1. Open Arceus X.
2. Open the script executor tab.
3. Paste the loadstring above.
4. Execute it.
5. A polished viewer will appear with dedicated tabs for Roles, Journals, and Summary, plus a draggable window, an Open Viewer button, and scrollable cards.
6. If the viewer still shows no role values, place the server helper file in ServerScriptService and run the script again.

## Optional server helper
For richer server-readable data, place the file `Flicker_Role_Viewer_Server.lua` into `ServerScriptService` in Roblox Studio.
This creates a small `RemoteFunction` that the viewer can use when it is available. The client script now falls back to local scanning if the server helper is not present or not exposing data.

## Important note
This script only reads values that are visible to the client. If Flicker stores role data inside server-only or hidden remote logic, no client-side script can reveal those values reliably.

## What the script does
- Creates a small on-screen panel.
- Scans the local player and nearby player data for role/rank/team/faction/title related values.
- Refreshes every second so the UI updates while you play.

## Verification
The script is intentionally client-side first, uses no exploit behavior, and is designed to be safe for Arceus X use. The optional server helper improves role/journal data collection when the game exposes those values.
