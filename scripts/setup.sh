#!/bin/bash
# =============================================================================
# setup.sh - One-time setup for Vortex SGEMM Lab
# Run this from a fresh Ubuntu environment.
# =============================================================================
 
set -e
 
echo "============================================="
echo "  Vortex SGEMM Lab - Environment Setup"
echo "============================================="
echo ""
 
# ---- Detect sudo ----
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
    echo "WARNING: No sudo available. Skipping system package install."
    echo "Make sure build-essential, cmake, ccache, verilator, git, wget are installed."
    echo ""
    SKIP_INSTALL=true
fi
 
# ---- Step 1: Install system dependencies ----
if [ "$SKIP_INSTALL" != "true" ]; then
    echo "[1/6] Installing system dependencies..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq \
        build-essential binutils python3 uuid-dev \
        git wget cmake ccache verilator
else
    echo "[1/6] Skipping system dependencies (no sudo)..."
fi
 
# ---- Step 2: Clone Vortex ----
echo ""
echo "[2/6] Cloning Vortex repository..."
if [ -d "$HOME/vortex" ]; then
    echo "  Vortex directory already exists at ~/vortex, skipping clone."
else
    git clone --depth=1 --recursive https://github.com/vortexgpgpu/vortex.git "$HOME/vortex"
fi
 
# ---- Step 3: Configure build ----
echo ""
echo "[3/6] Configuring build..."
cd "$HOME/vortex"
if [ ! -d "build" ]; then
    mkdir build
fi
cd build
../configure --xlen=32 --tooldir=$HOME/tools
 
# ---- Step 4: Install toolchain ----
echo ""
echo "[4/6] Installing RISC-V toolchain (this takes a while)..."
./ci/toolchain_install.sh --all
 
# ---- Step 5: Source environment and build ----
echo ""
echo "[5/6] Building Vortex..."
source ./ci/toolchain_env.sh
make -s
 
# Add toolchain env to bashrc for future sessions
if ! grep -q "toolchain_env.sh" ~/.bashrc 2>/dev/null; then
    echo "source $HOME/vortex/build/ci/toolchain_env.sh" >> ~/.bashrc
    echo "  Added toolchain_env.sh to ~/.bashrc"
fi
 
# ---- Step 6: Run baseline test ----
echo ""
echo "[6/6] Running baseline SGEMM test..."
./ci/blackbox.sh --driver=simx --cores=1 --app=sgemm --args="-n16"
 
echo ""
echo "============================================="
echo "  Setup complete!"
echo ""
echo "  Vortex is at:     ~/vortex/build"
echo "  SGEMM kernel:     ~/vortex/build/tests/opencl/sgemm/kernel.cl"
echo "  SGEMM common.h:   ~/vortex/build/tests/opencl/sgemm/common.h"
echo ""
echo "  To run with custom config:"
echo "    cd ~/vortex/build"
echo "    ~/CS254A_Lab1/scripts/run_sgemm.sh ~/CS254A_Lab1/configs/VX_config.toml"
echo ""
echo "  Remember: open a new terminal or run"
echo "    source ~/vortex/build/ci/toolchain_env.sh"
echo "============================================="