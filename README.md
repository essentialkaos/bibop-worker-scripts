<p align="center"><a href="#readme"><img src="https://gh.kaos.st/bibop-worker-scripts.svg"/></a></p>

<p align="center">
  <a href="https://travis-ci.com/essentialkaos/bibop-worker-scripts"><img src="https://travis-ci.com/essentialkaos/bibop-worker-scripts.svg"></a>
  <a href="#license"><img src="https://gh.kaos.st/apache2.svg"></a>
</p>

<p align="center"><a href="#installation">Installation</a> • <a href="#usage-example">Usage example</a> • <a href="#license">License</a></p>

<br/>

This repository contains scripts used on [bibop](https://github.com/essentialkaos/bibop) workers.

- `self-update.sh` — script for updating scripts to the latest versions;
- `update.sh` — script for updating `bibop` and `bibop-massive`;
- `dep.sh` — script for installing/uninstalling reqiured packages;
- `run.sh` — script for running tests.

### Installation

```bash
curl -# -L -o self-update.sh https://kaos.sh/bibop-worker-scripts/self-update.sh && chmod +x self-update.sh && ./self-update.sh && ./update.sh

```

### Usage example

```bash
./self-update.sh
./update.sh develop
./run.sh develop

```

### License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)

<p align="center"><a href="https://essentialkaos.com"><img src="https://gh.kaos.st/ekgh.svg"/></a></p>
