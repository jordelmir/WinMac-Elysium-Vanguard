# 🤖 WinMac Elysium Vanguard — AI Agent Operational & Performance Guide

> **For AI Agents**: This document describes how to control, diagnose, optimize, and launch
> games using the WinMac Elysium Vanguard engine. Read this first before operating the system.

---

## 🔌 Two Control Interfaces

### Interface 1: CLI (`elysium-cli`)

Run shell commands directly. The binary is at:
```
/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /.build/debug/elysium-cli
```

| Command | Purpose |
| :--- | :--- |
| `elysium-cli status` | Hardware, Wine runtimes, game library |
| `elysium-cli scan <folder>` | Auto-detect `.exe` in a game folder and register it |
| `elysium-cli launch <name>` | Launch a registered game with optimal profile |
| `elysium-cli gow2` | **Instant launch** Gears of War 2 (optimized anti-crash) |
| `elysium-cli diagnose` | Active Wine processes, GPU, RAM, logs |
| `elysium-cli perf` | **Full performance snapshot** with AI recommendations |
| `elysium-cli benchmark` | Measure Wine startup latency in milliseconds |
| `elysium-cli serve` | **Start AI Terminal HTTP server** on `localhost:19847` |
| `elysium-cli ai-guide` | Print this guide in terminal |

### Interface 2: HTTP JSON API (`localhost:19847`)

Start with `elysium-cli serve`. Then send HTTP requests:

#### `GET /health` — Server health check
```bash
curl http://localhost:19847/health
```
Response: `{"status": "ok", "server": "AITerminalServer", "port": "19847"}`

#### `GET /status` — System inspection (JSON)
```bash
curl http://localhost:19847/status
```
Returns hardware profile, Wine installations, registered games.

#### `GET /diagnose` — Performance telemetry
```bash
curl http://localhost:19847/diagnose
```
Returns CPU load, memory pressure, active Wine processes, disk usage.

#### `GET /logs` — Read diagnostic logs
```bash
curl http://localhost:19847/logs
```
Returns last 50 log lines from `~/Library/Application Support/ElysiumVanguard/Logs/`.

#### `POST /command` — Execute any shell command
```bash
curl -X POST http://localhost:19847/command \
  -H "Content-Type: application/json" \
  -d '{"command": "ps aux | grep wine | grep -v grep", "timeout": 10}'
```
Response includes `output`, `exitCode`, and `durationMs`.

#### `POST /launch` — Launch a game
```bash
curl -X POST http://localhost:19847/launch \
  -H "Content-Type: application/json" \
  -d '{"game": "gow2"}'
```
Response includes `pid` and launch status.

#### `GET /guide` — Machine-readable operational guide
```bash
curl http://localhost:19847/guide
```

---

## ⚡ Performance Optimization Playbook

When a game is **slow**, **stuttering**, or **crashing**, follow this decision tree:

### Step 1: Capture Performance Snapshot
```bash
elysium-cli perf
# OR
curl http://localhost:19847/diagnose
```

### Step 2: Identify the Bottleneck

| Symptom | Root Cause | Fix |
| :--- | :--- | :--- |
| Crash at startup with `alloc_pages_vprot` | 32-bit memory overflow on ARM64 | `WINE_LARGE_ADDRESS_AWARE=0` |
| FPS drops / stuttering | Thread sync contention | `WINEESYNC=1` and `WINEMSYNC=1` |
| Black screen or no render | Wrong D3D translation layer | `WINEDLLOVERRIDES="d3d9=builtin"` |
| `vulkan` error in logs | Vulkan driver not linked | Use `builtin` WineD3D, not DXVK |
| High CPU (>90%) on Wine process | Resolution too high | Lower to `-ResX=1024 -ResY=768` |
| Game freezes on splash screen | Splash screen hang | Add `-NOSPLASH -NOMOVIESTARTUP` |
| `Killed: 9` on any Wine binary | macOS Gatekeeper blocking | `codesign --force --deep --sign -` on Wine dir |

### Step 3: Apply Fixes

Edit environment variables in the launcher script:
```
/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /Scripts/launch_gow2_wine11.sh
```

Or send commands through the API:
```bash
curl -X POST http://localhost:19847/command \
  -d '{"command": "WINE_LARGE_ADDRESS_AWARE=0 WINEESYNC=1 /Users/jordelmirsdevhome/Wine/wine-11.13-install/bin/wine /path/to/game.exe -windowed"}'
```

---

## 📁 Key File Locations

| What | Path |
| :--- | :--- |
| Wine 11.13 binary | `/Users/jordelmirsdevhome/Wine/wine-11.13-install/bin/wine` |
| Wine libraries | `/Users/jordelmirsdevhome/Wine/wine-11.13-install/lib/wine/` |
| GoW2 launcher script | `/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /Scripts/launch_gow2_wine11.sh` |
| GoW2 game executable | `/Users/jordelmirsdevhome/Downloads/Juegos/Gear of War 2 Nativo/Binaries/GoW2Hollow.exe` |
| App bundle | `/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /build/Release/WinMac Elysium Vanguard.app` |
| Diagnostic logs | `~/Library/Application Support/ElysiumVanguard/Logs/` |
| Telemetry JSON | `~/Library/Application Support/ElysiumVanguard/Logs/telemetry.json` |
| Game bottles (prefixes) | `~/Library/Application Support/ElysiumVanguard/Bottles/` |
| CLI binary (debug) | `.build/debug/elysium-cli` |
| Project source | `/Users/jordelmirsdevhome/Downloads/Juegos/Win Mac Elysium Vanguard /` |
| Build script | `/Users/jordelmirsdevhome/Wine/build_wine11.sh` |

---

## 🎮 Quick Start for AI Agents

```bash
# 1. Check system readiness
elysium-cli status

# 2. Get performance baseline
elysium-cli perf

# 3. Launch Gears of War 2
elysium-cli gow2

# 4. Monitor while running
elysium-cli perf

# 5. If slow, diagnose
elysium-cli diagnose

# 6. Start HTTP API for programmatic control
elysium-cli serve
# Then use curl/fetch to http://localhost:19847/*
```

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│           WinMac Elysium Vanguard                   │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ ElysiumCLI   │  │ ElysiumApp   │  (entry points) │
│  │ (terminal)   │  │ (GUI .app)   │                 │
│  └──────┬───────┘  └──────┬───────┘                 │
│         │                 │                         │
│  ┌──────▼─────────────────▼───────┐                 │
│  │         ElysiumCore            │                 │
│  │  ┌───────────────────────────┐ │                 │
│  │  │ AITerminalServer (HTTP)   │ │  ← AI agents   │
│  │  │ AIPerformanceMonitor      │ │  ← telemetry   │
│  │  │ WineProcessLauncher       │ │  ← game launch │
│  │  │ HardwareProbe             │ │  ← GPU/CPU     │
│  │  │ ElysiumLogger             │ │  ← diagnostics │
│  │  │ GamePatchRegistry         │ │  ← auto-patch  │
│  │  │ ExeScanner                │ │  ← .exe detect │
│  │  └───────────────────────────┘ │                 │
│  └────────────────────────────────┘                 │
│                    │                                │
│  ┌─────────────────▼──────────────┐                 │
│  │  Wine 11.13 WoW64 (compiled)  │                 │
│  │  /Users/.../wine-11.13-install │                 │
│  │  ┌─────────┐ ┌──────────────┐  │                 │
│  │  │ i386 PE │ │ aarch64 PE   │  │                 │
│  │  │ (32bit) │ │ (64bit)      │  │                 │
│  │  └────┬────┘ └──────┬───────┘  │                 │
│  │       │ WoW64 thunk │          │                 │
│  │       └──────┬──────┘          │                 │
│  └──────────────┼─────────────────┘                 │
│                 ▼                                   │
│  ┌──────────────────────────────┐                   │
│  │   macOS Metal / OpenGL       │                   │
│  │   (GPU hardware)             │                   │
│  └──────────────────────────────┘                   │
└─────────────────────────────────────────────────────┘
```

---

*Authored by Antigravity AI Engine for WinMac Elysium Vanguard v1.0*
*Last updated: 2026-07-22*
