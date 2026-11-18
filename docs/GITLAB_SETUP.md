# Publish the prototype to AIP GitLab and then DRPHub

The prototype has **not** been pushed to GitLab. There is no authenticated GitLab write connection or confirmed target project in the current session. These commands are for a maintainer with permissions to create a project and push.

1. Create an empty GitLab project, e.g. `grapesph-revival`, under the appropriate AIP group. Avoid checking in historic GRAPESPH source until its redistribution permissions are clarified.
2. From the extracted repository root:

```sh
git init
git branch -M main
git add .
git commit -m 'Add experimental GRAPE-3 CPU Fortran compatibility prototype'
git remote add origin git@gitlab.aip.de:REPLACE_GROUP/grapesph-revival.git
git push -u origin main
```

3. Open the GitLab pipeline. The `cpu-smoke-test` runs automatically. The `build-container` job is manual and requires a Docker-in-Docker-enabled privileged runner; adapt it to the AIP runner's supported build mechanism before running.
4. Once the registry has a pushed image, update the `environment` in `reana.yaml` to that exact image. Prefer an immutable digest rather than a mutable tag. Make sure REANA can authenticate to and pull the image.
5. In REANA, upload the YAML workflow or submit it through your normal REANA CLI path, run the workflow, and retrieve `results/demo.csv`. This tests the packaged demo, not the original simulation.
6. Create a DRPHub card using `docs/drphub-card.md`, linking the GitLab repository, immutable container, workflow and verified results. Label it *experimental* until the historical Fortran sources and scientific validation are available.

## Outstanding for full original simulation

- Obtain the actual Matthias Steinmetz GRAPESPH Fortran source and associated data; do not confuse the Appendix A schematic with a complete program.
- Check Fortran declarations and how each GRAPE-3 function's arguments were represented on the historical compiler and host.
- Implement the actual GRAPE-3 neighbour-list overflow semantics or adapt the caller to receive complete CPU lists without historic board limits.
- Validate force precision/self-interaction and SPH observables, and then add representative astrophysical benchmark datasets to the DRPHub card.
