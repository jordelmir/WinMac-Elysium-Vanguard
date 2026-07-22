# 🌌 WinMac Elysium Vanguard

> **The next-generation Windows execution engine for macOS.**  
> *Dual Architecture: Apple Silicon (M-Series) & Intel Mac • Cyberpunk Neon UI • 1-Click Game Launch*

[![Build](https://github.com/jordelmir/WinMac-Elysium-Vanguard/actions/workflows/build.yml/badge.svg)](https://github.com/jordelmir/WinMac-Elysium-Vanguard/actions)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat&logo=swift)](https://swift.org)
[![Platform](https://img.shields.io/badge/macOS-14.0+-white?style=flat&logo=apple)](https://apple.com)
[![License](https://img.shields.io/badge/License-Proprietary-red?style=flat)]()

---

## ⚡ What Is This?

WinMac Elysium Vanguard is a **world-class, high-performance Windows game execution platform for macOS** that transforms your Mac into the ultimate gaming machine. Think **Winlator/GameHub for Mac** — but with a cyberpunk neon interface, automatic game engine detection, shader pre-caching, and zero-configuration 1-click game launching.

### Key Differentiators

| Feature | Whisky (Archived) | CrossOver | **Elysium Vanguard** |
|:---|:---|:---|:---|
| **UI/UX** | macOS stock | Standard | **Cyberpunk 3D Neon + Glassmorphism** |
| **Game Launch** | Manual setup | Manual setup | **1-Click Auto-Detection** |
| **Intel Mac Support** | ARM64 only | Both | **Native x86 + ARM64 dual pipeline** |
| **Engine Tuning** | None | None | **Auto-tune for UE5/Unity/REDengine** |
| **Shader Cache** | None | Basic | **Per-game pre-warming engine** |
| **Theme Customization** | None | None | **4-Tier Neon Color Customizer** |
| **Performance HUD** | MTL_HUD basic | None | **Real-time FPS/Frametime/VRAM** |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                 WinMac Elysium Vanguard Engine                  │
├──────────────────┬──────────────────┬───────────────────────────┤
│   ElysiumCore    │    ElysiumUI     │       ElysiumCLI          │
│                  │                  │                           │
│ • HardwareProbe  │ • NeonTheme      │ • status (diagnostics)    │
│ • ExeScanner     │ • GlassCardView  │ • scan <folder>           │
│ • BottleManager  │ • ParticleView   │ • launch <game>           │
│ • WineProcess    │ • GameCardView   │                           │
│ • GameEngine     │ • PerformHUD     │                           │
│ • ShaderCache    │ • SettingsView   │                           │
│ • DependencyInj  │ • GameLibrary    │                           │
│ • PatchRegistry  │                  │                           │
│ • LibraryStore   │                  │                           │
└──────────────────┴──────────────────┴───────────────────────────┘
                           │
          ┌────────────────┴────────────────┐
          ▼                                 ▼
┌────────────────────┐           ┌────────────────────┐
│ Apple Silicon ARM64│           │  Intel Mac x86_64  │
├────────────────────┤           ├────────────────────┤
│ Rosetta 2 + D3D-  │           │ Native x86 exec +  │
│ Metal (GPTK 2.x)  │           │ DXVK + VKD3D-Proton│
│ + MetalFX Upscale │           │ + MoltenVK engine  │
└────────────────────┘           └────────────────────┘
```

---

## 🚀 Quick Start

### Build & Run (CLI)
```bash
git clone https://github.com/jordelmir/WinMac-Elysium-Vanguard.git
cd WinMac-Elysium-Vanguard
swift build
swift run elysium-cli status
```

### Scan & Launch a Game
```bash
swift run elysium-cli scan /path/to/extracted/game/folder
swift run elysium-cli launch "Game Name"
```

### Build GUI App
```bash
chmod +x Scripts/build_release_app.sh
./Scripts/build_release_app.sh
open "build/Release/WinMac Elysium Vanguard.app"
```

---

## 🎨 Neon Theme Customizer

4-tier phosphorescent color control with live preview:

| Tier | Default | Hex |
|:---|:---|:---|
| **Primary** | Electric Cyan | `#00F0FF` |
| **Secondary** | Neon Magenta | `#FF007F` |
| **Tertiary** | Phosphorescent Lime | `#39FF14` |
| **Quaternary** | Plasma Orange | `#FF6600` |

Built-in presets: **Cyberpunk Default**, **Matrix Green**, **Vaporwave Sunset**

---

## 🧪 Testing

```bash
swift test
# 14 tests, 0 failures
```

---

## 📦 Project Structure

```
Sources/
├── ElysiumCore/          # Translation engine & game management
│   ├── HardwareProbe.swift
│   ├── ExeScanner.swift
│   ├── BottleManager.swift
│   ├── WineProcessLauncher.swift
│   ├── GameEngineProfile.swift
│   ├── ShaderCacheManager.swift
│   ├── DependencyInjector.swift
│   ├── GamePatchRegistry.swift
│   └── GameLibraryStore.swift
├── ElysiumUI/            # Cyberpunk SwiftUI interface
│   ├── NeonThemeEngine.swift
│   ├── NeonGlassCardView.swift
│   ├── NeonParticleBackgroundView.swift
│   ├── GameCardView.swift
│   ├── GameLibraryView.swift
│   ├── PerformanceHUDView.swift
│   └── SettingsView.swift
├── ElysiumCLI/           # Command-line diagnostic & launcher
│   └── main.swift
└── ElysiumApp/           # Native macOS GUI application
    └── main.swift
```

---

*Built with 💜 by Antigravity for the WinMac Elysium Vanguard Team.*
