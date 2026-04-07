# SGEMM Roofline Analysis on Vortex GPGPU

## Lab Objective

Conduct a roofline analysis of SGEMM (Single-precision General Matrix Multiply) on the Vortex RISC-V GPGPU. Your goal is to achieve **≥50% of peak performance on a single core**. Achieving above 50% earns a **+1pt bonus**.

**Peak performance formula:**
```
Peak = 2 × NUM_THREADS × NUM_FPU_BLOCKS  (flops/cycle)
```

## What You Can Modify

| File | Purpose |
|------|---------|
| `kernel.cl` | Optimize the SGEMM kernel (tiling, shared memory, etc.) |
| `common.h` | Change `BLOCK_SIZE_X/Y/Z`, `GRID_SIZE_X/Y/Z` |
| `configs/VX_config.toml` | Change hardware: `NUM_THREADS`, `NUM_WARPS`, `NUM_FPU_BLOCKS`, caches, etc. |

**Do NOT modify** any other Vortex source files.

---

## Quick Start

### 1. Clone this repo

```bash
git clone https://github.com/<your-org>/sgemm-lab.git
cd sgemm-lab
```

### 2. Run the setup script (one-time)

This installs all dependencies, clones Vortex, builds the toolchain, and runs the baseline.

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

> **Note:** This takes 30-60 minutes on first run (toolchain download + build).

### 3. Run the baseline

```bash
cd ~/vortex/build
~/sgemm-lab/scripts/run_sgemm.sh ~/sgemm-lab/configs/VX_config.toml
```

You should see `PASSED!` and performance counters at the end.

### 4. Record your baseline

From the output, note:
- `cycles` from the `PERF:` line
- Calculate: `achieved = 2 × N³ / cycles`
- Calculate: `efficiency = achieved / peak × 100%`

### 5. Optimize

Edit the kernel and hardware config, then re-run:

```bash
# Edit the kernel
nano ~/vortex/build/tests/opencl/sgemm/kernel.cl

# Edit block sizes
nano ~/vortex/build/tests/opencl/sgemm/common.h

# Edit hardware config
nano ~/sgemm-lab/configs/VX_config.toml

# Re-run
cd ~/vortex/build
~/sgemm-lab/scripts/run_sgemm.sh ~/sgemm-lab/configs/VX_config.toml
```

---

## Optimization Hints

1. **Tiling with shared memory** — Load tiles of A and B into `__local` memory to reduce global memory accesses. See `tests/opencl/sgemm2/` and `tests/opencl/sgemm3/` for reference.

2. **Match block size to warp size** — Set `BLOCK_SIZE` in `common.h` to match `NUM_THREADS` in `VX_config.toml` for full warp utilization.

3. **Increase FPU throughput** — More `NUM_FPU_BLOCKS` increases peak, but your kernel must have enough independent FP operations to keep them busy.

4. **Tune cache sizes** — Larger `DCACHE_SIZE` or `SMEM_SIZE` can reduce memory stalls for larger matrices.

5. **Balance warps and threads** — More warps help hide memory latency; more threads increase parallelism per warp.

---

## Deliverables

1. Modified `kernel.cl` and `common.h`
2. Your `VX_config.toml` with chosen hardware configuration
3. A short report including:
   - Baseline performance (flops/cycle, efficiency %)
   - Optimized performance (flops/cycle, efficiency %)
   - Explanation of what you changed and why
   - Roofline plot showing baseline vs. optimized

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `cmake: not found` | `sudo apt-get install cmake` |
| `ccache: not found` | `sudo apt-get install ccache verilator` |
| `riscv32-unknown-elf-gcc: No such file` | Run `./ci/toolchain_install.sh --all` and `source ./ci/toolchain_env.sh` |
| blackbox.sh prints usage only | Check for typos: `--cores` not `--core`, use `--args="-n64"` with quotes |
| `FAILED` after run | Your kernel has a bug — check matrix output vs. reference |
