# README

Bash run command (bashrc) scripts that provide useful commands.

## Installation

Option A. With bashrc-installer

```bash
# First install bashrc-installer with curl
curl -fsSL https://raw.githubusercontent.com/istergiou/bashrc-installer/main/install.sh | bash
# or wget
wget -qO- https://raw.githubusercontent.com/istergiou/bashrc-installer/main/install.sh | bash

# create ~/.bashrc.d and wire it into ~/.bashrc
bashrc-installer prepare          

# install
bashrc-installer install github.com/istergiou/bashrc-base
```

Option B. Without bashrc-installer

```bash
source /path/to/cenv.sh
source /path/to/favourite.sh
```

## Usage

- [cenv](cenc.README.md)
- [favourite](favourite.README.md)

