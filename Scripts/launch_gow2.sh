#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# 🎮 WINMAC ELYSIUM VANGUARD — Gears of War 2 Launcher
# ═══════════════════════════════════════════════════════════════════
# Optimized launch script for GoW2 (UE3 32-bit) on Apple Silicon
# Addresses: virtual.c assertion, texture streaming crashes, 
#            missing runtimes, and D3D9 compatibility
# ═══════════════════════════════════════════════════════════════════

set -e

GAME_DIR="/Users/jordelmirsdevhome/Downloads/Juegos/Gear of War 2 Nativo"
GAME_EXE="$GAME_DIR/Binaries/GoW2Hollow.exe"
WINE="/Applications/Wine Stable.app/Contents/Resources/wine/bin/wine"
GOW2_PREFIX="$HOME/Library/Application Support/ElysiumVanguard/Bottles/GoW2_Prefix"
LOG_DIR="$HOME/Library/Application Support/ElysiumVanguard/Logs"

mkdir -p "$LOG_DIR"

echo "🌌 ════════════════════════════════════════════════════ 🌌"
echo "⚡  GEARS OF WAR 2 — ELYSIUM VANGUARD LAUNCHER        ⚡"
echo "🌌 ════════════════════════════════════════════════════ 🌌"

# ── WINEPREFIX ──────────────────────────────────────────────
export WINEPREFIX="$GOW2_PREFIX"
export WINEARCH=win64

# ── CRITICAL: Suppress debug noise, keep only errors ────────
export WINEDEBUG=fixme-all,warn-all

# ── ESYNC for better thread performance ─────────────────────
export WINEESYNC=1

# ── UE3/D3D9 Compatibility Environment ─────────────────────
# ── wined3d Vulkan Renderer ─────────────────────────────────
# Tell Wine's wined3d to render Direct3D 9 via Vulkan (MoltenVK) directly
export WINE_D3D_CONFIG="renderer=vulkan"
export WINEDLLOVERRIDES="d3d9=builtin;d3d11=builtin;dxgi=builtin;d3d10core=builtin;dbghelp=n,b;steam_api=n"

# ── GPTK D3D Metal translation layer settings ──────────────
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLSL_VERSION_OVERRIDE=460

# ── Memory management workarounds for 32-bit on ARM64 ──────
# Reduce virtual memory pressure that triggers alloc_pages_vprot crash
export WINE_LARGE_ADDRESS_AWARE=0
export WINE_HEAP_DELAY_FREE=0
export STAGING_SHARED_MEMORY=1
export STAGING_WRITECOPY=1

# ── Apple Silicon / Metal GPU settings ──────────────────────
export MTL_HUD_ENABLED=0
export MVK_CONFIG_RESUME_LOST_DEVICE=1
export MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS=2

# ── UE3 specific: Disable problematic texture streaming ────
# This prevents the massive virtual memory allocations that crash Wine
export UE3_DISABLE_TEXTURE_STREAMING=1

echo ""
echo "  🔧 Wine Prefix: $WINEPREFIX"
echo "  🎮 Game: $GAME_EXE"
echo "  🖥️  Wine: $($WINE --version 2>/dev/null)"
echo ""

# ── Kill leftover wine processes ────────────────────────────
pkill -9 -f wineserver 2>/dev/null || true
sleep 1

# ── Apply UE3 config patches (disable texture streaming) ───
CONFIG_DIR="$GAME_DIR/GearGame/Config"
CUSTOM_ENGINE="$CONFIG_DIR/GearEngine.ini"

# Backup original if not already backed up
if [ ! -f "$CUSTOM_ENGINE.original" ]; then
    cp "$CUSTOM_ENGINE" "$CUSTOM_ENGINE.original"
    echo "  📋 Backed up original GearEngine.ini"
fi

# Patch: disable texture streaming and background level streaming
# These are the primary causes of the virtual.c assertion
if grep -q "bUseTextureStreaming=True" "$CUSTOM_ENGINE"; then
    sed -i '' 's/bUseTextureStreaming=True/bUseTextureStreaming=False/g' "$CUSTOM_ENGINE"
    echo "  ✅ Disabled bUseTextureStreaming"
fi

if grep -q "bUseBackgroundLevelStreaming=True" "$CUSTOM_ENGINE"; then
    sed -i '' 's/bUseBackgroundLevelStreaming=True/bUseBackgroundLevelStreaming=False/g' "$CUSTOM_ENGINE"
    echo "  ✅ Disabled bUseBackgroundLevelStreaming"
fi

# Reduce texture pool size to prevent memory overflow
if grep -q "PoolSize=140" "$CUSTOM_ENGINE"; then
    sed -i '' 's/PoolSize=140/PoolSize=64/g' "$CUSTOM_ENGINE"
    echo "  ✅ Reduced TextureStreaming PoolSize to 64MB"
fi

echo ""
echo "  🚀 Launching Gears of War 2..."
echo ""

# ── LAUNCH ──────────────────────────────────────────────────
cd "$GAME_DIR/Binaries"
"$WINE" "$GAME_EXE" -windowed -ResX=1280 -ResY=720 -NOVSYNC 2>&1 | tee "$LOG_DIR/gow2_launch.log" &
WINE_PID=$!

echo "  ⚡ Wine PID: $WINE_PID"
echo "  📝 Log: $LOG_DIR/gow2_launch.log"
echo ""
echo "  Waiting for game process..."

# Wait a moment then check if it's alive
sleep 5
if kill -0 $WINE_PID 2>/dev/null; then
    echo "  ✅ Game process is running!"
    echo ""
    echo "  Press Ctrl+C to stop monitoring (game will continue running)"
    wait $WINE_PID 2>/dev/null
    echo "  🏁 Game exited with code: $?"
else
    echo "  ❌ Game process died. Checking logs..."
    tail -30 "$LOG_DIR/gow2_launch.log"
fi
