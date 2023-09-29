<p align="center"><a href="#readme"><img src="https://gh.kaos.st/bibop-worker-scripts.svg"/></a></p>

<p align="center">
  <a href="https://github.com/essentialkaos/bibop-worker-scripts/actions"><img src="https://github.com/essentialkaos/bibop-worker-scripts/workflows/CI/badge.svg" alt="GitHub Actions Status" /></a>
  <a href="#license"><img src="https://gh.kaos.st/apache2.svg"></a>
</p>

<p align="center"><a href="#installation">Installation</a> • <a href="#license">License</a></p>

<br/>

This repository contains scripts used on [bibop](https://github.com/essentialkaos/bibop) workers.

- `self-update.sh` — script for updating scripts to the latest versions;
- `update.sh` — script for updating `bibop` and `bibop-massive`;
- `run.sh` — script for running tests.

### Installation

```bash
bash <(curl -fsSL https://kaos.sh/bibop-worker-scripts/self-update.sh) && ./update.sh

```

### Usage

```
Usage: ./run.sh {options} branch

Options

  --prepare, -P      Prepare system for tests
  --validate, -V     Validate recipes (dry run)
  --recheck, -R      Recheck failed tests
  --no-color, -nc    Disable colors in output
  --help, -h         Show this help message
  --version, -v      Show information about version

Examples

  ./run.sh --prepare
  Prepare system for tests

  ./run.sh master
  Run bibop tests from master branch of kaos-repo
```

```
Usage: ./update.sh {options}

Options

  --branch, -b branch            Source branch (default: master)
  --bibop-version, -B version    Bibop version (default: latest)
  --quiet, -q                    Don't output anything
  --no-color, -nc                Disable colors in output
  --help, -h                     Show this help message
  --version, -v                  Show information about version

Examples

  ./update.sh --branch develop --bibop-version 4.7.0
  Update scripts to versions from master branch and download bibop 4.7.0
```

```
Usage: ./self-update.sh {options}

Options

  --quiet, -q                Don't output anything
  --no-color, -nc            Disable colors in output
  --help, -h                 Show this help message
  --version, -v              Show information about version
```

### License

[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0)

<p align="center"><a href="https://essentialkaos.com"><img src="https://gh.kaos.st/ekgh.svg"/></a></p>
