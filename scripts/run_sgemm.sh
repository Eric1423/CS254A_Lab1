#!/bin/bash
# =============================================================================
# run_sgemm.sh - Run SGEMM on Vortex using VX_config.toml
# Usage: ./run_sgemm.sh [config_file]
# =============================================================================

CONFIG_FILE="${1:-VX_config.toml}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found."
    exit 1
fi

# Helper: read a value from the TOML file
read_val() {
    grep -E "^$1\s*=" "$CONFIG_FILE" | head -1 | awk -F'=' '{print $2}' | tr -d ' "' | tr -d "'"
}

# ---- Read hardware config (these become -D flags) ----
NUM_THREADS=$(read_val NUM_THREADS)
NUM_WARPS=$(read_val NUM_WARPS)
NUM_FPU_BLOCKS=$(read_val NUM_FPU_BLOCKS)
NUM_ALU_BLOCKS=$(read_val NUM_ALU_BLOCKS)
NUM_LSU_BLOCKS=$(read_val NUM_LSU_BLOCKS)
ISSUE_WIDTH=$(read_val ISSUE_WIDTH)
DCACHE_SIZE=$(read_val DCACHE_SIZE)
SMEM_SIZE=$(read_val SMEM_SIZE)
L2_ENABLE=$(read_val L2_ENABLE)

# ---- Read simulation config (these become --flags) ----
DRIVER=$(read_val driver)
CORES=$(read_val cores)
CLUSTERS=$(read_val clusters)
MATRIX_SIZE=$(read_val matrix_size)

# Defaults
DRIVER="${DRIVER:-simx}"
CORES="${CORES:-1}"
CLUSTERS="${CLUSTERS:-1}"
MATRIX_SIZE="${MATRIX_SIZE:-16}"
NUM_THREADS="${NUM_THREADS:-4}"
NUM_FPU_BLOCKS="${NUM_FPU_BLOCKS:-1}"

# ---- Build CONFIGS (hardware -D flags) ----
CONFIGS=""
CONFIGS="$CONFIGS -DNUM_THREADS=$NUM_THREADS"
CONFIGS="$CONFIGS -DNUM_WARPS=${NUM_WARPS:-4}"
CONFIGS="$CONFIGS -DNUM_FPU_BLOCKS=$NUM_FPU_BLOCKS"
[ -n "$NUM_ALU_BLOCKS" ] && CONFIGS="$CONFIGS -DNUM_ALU_BLOCKS=$NUM_ALU_BLOCKS"
[ -n "$NUM_LSU_BLOCKS" ] && CONFIGS="$CONFIGS -DNUM_LSU_BLOCKS=$NUM_LSU_BLOCKS"
[ -n "$ISSUE_WIDTH" ]    && CONFIGS="$CONFIGS -DISSUE_WIDTH=$ISSUE_WIDTH"
[ -n "$DCACHE_SIZE" ]    && CONFIGS="$CONFIGS -DDCACHE_SIZE=$DCACHE_SIZE"
[ -n "$SMEM_SIZE" ]      && CONFIGS="$CONFIGS -DSMEM_SIZE=$SMEM_SIZE"
[ "$L2_ENABLE" = "true" ] && CONFIGS="$CONFIGS -DL2_ENABLE"

# ---- Calculate peak ----
PEAK=$(( 2 * NUM_THREADS * NUM_FPU_BLOCKS ))
FLOPS=$(( 2 * MATRIX_SIZE * MATRIX_SIZE * MATRIX_SIZE ))

# ---- Print summary ----
echo "============================================="
echo "  HARDWARE CONFIG (CONFIGS flags)"
echo "    Threads/warp:  $NUM_THREADS"
echo "    Warps/core:    ${NUM_WARPS:-4}"
echo "    FPU blocks:    $NUM_FPU_BLOCKS"
echo "    Issue width:   ${ISSUE_WIDTH:-1}"
echo "    DCache:        ${DCACHE_SIZE:-4096} B"
echo "    Shared mem:    ${SMEM_SIZE:-4096} B"
echo "    L2 cache:      ${L2_ENABLE:-false}"
echo ""
echo "  SIMULATION CONFIG (blackbox.sh flags)"
echo "    Driver:        $DRIVER"
echo "    Cores:         $CORES"
echo "    Clusters:      $CLUSTERS"
echo "    Matrix size:   ${MATRIX_SIZE}x${MATRIX_SIZE}"
echo ""
echo "  PERFORMANCE TARGETS"
echo "    Peak:          $PEAK flops/cycle"
echo "    50% target:    $(( PEAK / 2 )) flops/cycle"
echo "    Total flops:   $FLOPS"
echo "============================================="
echo ""

# ---- Run ----
CONFIGS="$CONFIGS" ./ci/blackbox.sh \
    --driver=$DRIVER \
    --clusters=$CLUSTERS \
    --cores=$CORES \
    --app=sgemm \
    --args="-n$MATRIX_SIZE"

echo ""
echo "  Efficiency formula:"
echo "  achieved_flops_per_cycle = $FLOPS / cycles"
echo "  efficiency = achieved / $PEAK × 100%"
echo "============================================="
