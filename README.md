# Installer for Lingua Franca tools

The `install.sh` script in this repo is offered as a convenient means for installing software in the Lingua Franca toolchain **on Linux and macOS**.
More detailed documentation is forthcoming, but here a few useful ways of using this script:

## To install the stable CLI tools, run:
```bash
curl -Ls https://i.lf-lang.org | bash -s cli
```

## To install the nightly CLI tools, run:
```bash
curl -Ls https://i.lf-lang.org | bash -s nightly cli
```

## To install the stable release of Epoch, run:
```bash
curl -Ls https://i.lf-lang.org | bash -s epoch
```

## To install the nightly release of Epoch, run:
```bash
curl -Ls https://i.lf-lang.org | bash -s nightly epoch
```

## Installation on Windows
The installer can also be used to install Lingua Franca in Windows Subsystem for Linux (WSL). Native Windows tooling can be [installed manually](#manual-installation).

## Manual installation
Please refer to our published release artifacts:
 - [CLI Tools](https://github.com/lf-lang/lingua-franca/releases/latest)
 - [Epoch IDE](https://github.com/lf-lang/epoch/releases/latest)
 
To install these, simply download the appropriate `.zip` or `.tar.gz` archives, decompress them, and place the contents in your file system.
