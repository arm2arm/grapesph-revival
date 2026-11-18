# GitHub repository and development workflow

The GRAPE-3 CPU prototype is published at https://github.com/arm2arm/grapesph-revival.

## Clone and run

```sh
git clone https://github.com/arm2arm/grapesph-revival.git
cd grapesph-revival
make test
```

The GitHub Actions workflow `.github/workflows/ci.yml` compiles the Fortran/C demo on Ubuntu and runs `make test` for pushes and pull requests. Results are available as an Actions artifact. CI validates **only the prototype**, not the historical GRAPESPH code.

## Scientific and licensing status

This repository contains a **new CPU-based GRAPE-3 interface experiment**, not Matthias Steinmetz's original Fortran program. The MIT license applies only to prototype files in this archive; the historical sources must not be added until permission and provenance are resolved. Confirm the actual GRAPE-3 ABI against the recovered Fortran code before attempting to link it.

The `reana.yaml` image address is a placeholder pointing at an AIP GitLab registry; update it after independently building and publishing a usable container image. A GitHub push alone does not make the REANA workflow runnable.
