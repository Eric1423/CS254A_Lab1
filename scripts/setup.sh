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

# ---- Step 1: Install system dependencies ----
echo "[1/6] Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    build-essential binutils python3 uuid-dev \
    git wget cmake ccache verilator

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
echo "    ~/sgemm-lab/scripts/run_sgemm.sh ~/sgemm-lab/configs/VX_config.toml"
echo ""
echo "  Remember: open a new terminal or run"
echo "    source ~/vortex/build/ci/toolchain_env.sh"
echo "============================================="
