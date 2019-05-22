## Bibop Worker Scripts

This repository contains scripts used on [bibop](https://github.com/essentialkaos/bibop) workers.

- `self-update.sh` — script for updating scripts to the latest versions;
- `update.sh` — script for updating `bibop` and `bibop-massive`;
- `run.sh` — script for running tests.

### Simple installation

```bash
curl -# -L -o self-update.sh https://kaos.sh/bibop-worker-scripts/self-update.sh && chmod +x self-update.sh && ./self-update.sh

```

### Usage example

```bash
./self-update.sh
./update.sh develop
./run.sh develop

```
