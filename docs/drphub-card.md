# DRPHub card proposal: GRAPESPH — GRAPE-3 CPU revival

**Type:** Reproducible Digital Research Product (prototype, not historical-code reproduction)

**Summary:** A Docker/REANA demonstration of the GRAPE-3 Fortran interface used by Matthias Steinmetz's GRAPESPH (1996). Executes CPU direct-summation gravity and neighbour search without GRAPE boards, with a self-testing Fortran client.

**Status:** Experimental GRAPE-3 API subset; not GRAPESPH simulation code.

**Tags:** astrophysics, cosmological simulations, SPH, GRAPE-3, historical-code-revival, Fortran, CPU-emulation, REANA, Docker

**Source:** https://github.com/arm2arm/grapesph-revival

**Container:** `registry.gitlab.aip.de/<group>/<project>/grapesph-grape3-cpu:<immutable-tag>` after CI publication.

**Workflow:** `reana.yaml` (replace registry placeholder). Step executes `grape3_demo` and exports `results/demo.csv`.

**Reproduce:** `make test`, or `make docker-build && make docker-run`, or `reana-client run -w ...` after image publication and REANA configuration.

**Provenance:** Steinmetz (1996), MNRAS 278, 1005–1017, doi:10.1093/mnras/278.4.1005. Appendix A supplies GRAPE-3 call examples but not full source. AMUSE's `g6lib` is a GRAPE-6 CPU emulator and does not implement neighbour list retrieval.

**Validation requirements for a research-grade card:** full original Fortran source and license; original input/test data; checked ABI and precision; cross-compared force/potential/neighbour list against reference; documented overflow behavior; pinned container digests; CI results archived; scientific plots and checksums.

**Important caveat:** Never label this prototype as a validated reproduction of the 1996 GRAPESPH simulations. It only validates a small API bridge and a three-particle example.
