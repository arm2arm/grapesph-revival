# GRAPESPH revival: GRAPE-3 CPU compatibility experiment

A **tested miniature GRAPE-3 Fortran-to-C CPU interface** and Docker/REANA packaging proposal for historical-code recovery. Inspired by the GRAPE-3 call sequence in Matthias Steinmetz, *GRAPESPH: cosmological smoothed particle hydrodynamics simulations with the special-purpose hardware GRAPE*, MNRAS **278**, 1005–1017 (1996), https://doi.org/10.1093/mnras/278.4.1005 (Appendix A).

> **Not the original GRAPESPH source; not yet a complete/hardware-accurate GRAPE-3 emulator.** The historical Fortran code has **not** been obtained. No claim of reproducibility for the actual 1996 cosmological simulation is made.

## What exists in this repository

- `src/grape3_cpu.c`: self-contained CPU direct-summation force/potential backend (`G=1`) and neighbour lists, exposed as conventional gfortran-compatible GRAPE-3 symbols.
- `src/demo.f90`: three-particle Fortran client, checks forces against independent summation, checks chip-specific neighbour sets, writes `results/demo.csv`.
- `Makefile`: native compile/test and Docker commands.
- `Dockerfile`: two-stage CPU-only image; verifies the demo at build time.
- `reana.yaml`: REANA serial-workflow template, to be edited with the deployed image.
- `.gitlab-ci.yml`: CPU test job plus opt-in manual image publication job for a privileged DIND runner.
- `.github/workflows/ci.yml`: GitHub Actions compile/validation job; publishes demo output as an artifact.
- `docs/GITHUB_SETUP.md`: repository clone and development instructions.
- `docs/drphub-card.md`: draft DRPHub card metadata and reproducibility caveats.

## Run locally

Requires GNU `make`, `gcc`, and `gfortran`.

```sh
make test
cat results/demo.csv
```

## Docker

```sh
make docker-build
make docker-run
cat results/demo.csv
```

Or directly:

```sh
docker build -t grapesph-grape3-cpu:0.1.0 .
mkdir -p results
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$(pwd)/results:/workspace/results" \
  grapesph-grape3-cpu:0.1.0 \
  /usr/local/bin/grape3_demo results/demo.csv
```

Docker was **not installed in the build/verification environment** here; the native build is used as the functional verification. Docker build/runtime and REANA workflow require checks at AIP.

## Implemented GRAPE-3 call subset

`g3init`, `g3free`, `g3nchips`, `g3setscales`, `g3seteps2`, `g3setn`, `g3setxj`, `g3setmj`, `g3seth2`, `g3frc`, `g3readnbl`, and `g3getnbl`.

Zero-based GRAPE particle/chip indices and Fortran arrays `(3,ni)` are used, matching the style of Appendix A. All floating-point ABI arguments in **this prototype** are `REAL*8` (`real(real64)`), and Fortran scalar integer arguments are default 32-bit integers. Do not assume old sources match this ABI; inspect their declarations before linking. The code uses the gfortran trailing-underscore symbol convention and is not portable unchanged to every Fortran compiler.

### Deliberate differences from original GRAPE hardware

- Double-precision CPU sums, not GRAPE-3 fixed-point arithmetic, rounding, scaling or identical accumulation order. Scale arguments are accepted but not applied.
- `G=1` unit system and Plummer-type softening, with zero-distance terms excluded even from potential: potential normalization/self-interaction must be checked against historical data.
- Per-chip neighbour lists include self when within the radius, use radius-squared comparison `r² <= h²`, and are emitted in **descending zero-based particle-address order**.
- **No original GRAPE-3 disjunct neighbour-mask encoding or 1023-word overflow-recovery protocol.** A query with more than 1022 distinct neighbours fails explicitly to prevent unscientific silent results. Full SPH runs need that semantics implemented or the original routine patched to use unbounded host neighbour lists.
- CPU only and O(N × N_active) per force call, not accelerated or performance-matched to historic hardware.
- Does not implement density, pressure, artificial viscosity, cooling, integration, cosmological boundary conditions or the original timestepping algorithm.

## Why not directly link AMUSE's GRAPE-6 emulator?

`amusecode/amuse` contains `lib/g6lib`, described by its `Makefile` as a GRAPE-6 emulation library. The examined implementation calculates gravity, but the exported `g6_get_neighbour_list_` returns without populating the output; this is insufficient for SPH and is not ABI-compatible with GRAPE-3 calls. `lib/sapporo_light` is a distinct **GPU** GRAPE-6 approach with an old CUDA toolchain; it cannot serve as a drop-in GRAPE-3 backend.

- https://github.com/amusecode/amuse/tree/main/lib/g6lib
- https://github.com/amusecode/amuse/blob/main/lib/g6lib/g6lib.c
- https://github.com/amusecode/amuse/tree/main/lib/sapporo_light

## Reproduction roadmap

1. **Recover the original source and permission to redistribute.** Search AIP/MPA archives, old Fortran tarballs and backups; ask Matthias Steinmetz and past collaborators. Locate input parameter files, units, ICs and reference outputs.
2. **Audit Fortran ABI and functionality.** Extract all `g3*`/GRAPE calls with `grep -RinE '\b(g3[a-z0-9_]+|grape[a-z0-9_]*)' .`; map scalar/array types, fixed/free-form Fortran, byte order, COMMON blocks, global symbols and compiler assumptions.
3. **Complete GRAPE-3 compatibility.** Handle dynamic chip count, masks/overflow/restart semantics, precision and target-model gravitational softening. Make the SPH neighbour algorithm validated, not just the demo.
4. **Validate physical results.** Hand-check tiny N-body scenarios, neighbour membership at exact cutoffs, overflow edge cases, conservation tests and known SPH benchmarks. Compare against archived data and document differences from fixed-point GRAPE arithmetic.
5. **Publish immutable container and CI.** Build on GitLab AIP; replace `REPLACE_*` in `reana.yaml` with a real image and pin a digest. Ensure image is accessible to the REANA cluster, archive outputs and checksums.
6. **Create the DRPHub card.** Add source, abstract, provenance and limits, DOI, image digest, REANA workflow, input datasets and validated outputs. Only claim historical reproducibility after the full tests pass.

## REANA at AIP

REANA job containers must pull the image via the target cluster's registry credentials/pull secret as applicable. The `reana.yaml` template runs the **demo**, not full GRAPESPH. Build/push the image in GitLab and edit the environment URL before using `reana-client`.

## References

1. Steinmetz, M. (1996), MNRAS, 278, 1005–1017. https://doi.org/10.1093/mnras/278.4.1005; https://adsabs.harvard.edu/pdf/1996MNRAS.278.1005S
2. AMUSE library implementations: https://github.com/amusecode/amuse/tree/main/lib/g6lib and https://github.com/amusecode/amuse/tree/main/lib/sapporo_light
