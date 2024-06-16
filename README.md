<p align="center"><a href="#readme"><img src=".github/images/card.svg"/></a></p>

<p align="center">
  <a href="https://github.com/essentialkaos/bibop-worker-scripts/actions"><img src="https://github.com/essentialkaos/bibop-worker-scripts/workflows/CI/badge.svg" alt="GitHub Actions Status" /></a>
  <a href="#license"><img src=".github/images/license.svg"/></a>
</p>

<p align="center"><a href="#installation">Installation</a> • <a href="#license">License</a></p>

<br/>

This repository contains scripts used on [bibop](https://kaos.sh/bibop) workers.

- `self-update.sh` — script for updating scripts to the latest versions;
- `update.sh` — script for updating `bibop` and `bibop-massive`;
- `run.sh` — script for running tests.

### Installation

```bash
bash <(curl -fsSL https://kaos.sh/bibop-worker-scripts/self-update.sh) && /bibop/update.sh

```

### Usage

<img src=".github/images/run-usage.svg"/>

<img src=".github/images/update-usage.svg"/>

<img src=".github/images/self-update-usage.svg"/>

### License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)

<p align="center"><a href="https://essentialkaos.com"><img src="https://gh.kaos.st/ekgh.svg"/></a></p>
