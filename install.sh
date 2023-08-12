#!/bin/bash
set -eo pipefail

# Installer for Lingua Franca tools.
# 
# To install the stable CLI tools, run:
# curl -s https://install.lf-lang.org | bash -s cli
# To install the nightly CLI tools, run:
# curl -s https://install.lf-lang.org | bash -s nightly cli
#
# To install the stable release of Epoch, run:
# curl -s https://install.lf-lang.org | bash -s epoch
# To install the nightly release of Epoch, run:
# curl -s https://install.lf-lang.org | bash -s nightly epoch

tools=(cli epoch)
selected=()

install() (
  case $1 in
    cli)
      cp -rf $dir/bin/* $prefix/bin/
      cp -rf $dir/lib/* $prefix/lib/
    ;;
  esac
  echo "    - Installed: $(ls --format=commas $dir/bin/)"
)

cleanup() (
  case $1 in
    cli)
      rm -rf $dir
    ;;
  esac
)

download() (
  case $1 in
    cli)
      echo "    - Unpacking into $tmp"
      curl -sL $url | tar xfz - -C $tmp
    ;;
  esac
)

# Parse arguments
for i in "$@"
do
# FIXME: add -p/--prefix
case $i in
    all)
    selected=$all_tools
    ;;
    cli)
    selected+=("cli")
    ;;
    epoch)
    selected+=("epoch")
    ;;
    nightly)
    if [[ -z $kind ]]; then
      kind="nightly"
    else
      echo "You can only use one qualifier; choose 'stable' or 'nightly'."
      exit 1
    fi
    ;;
    stable)
    if [[ -z $kind ]]; then
      kind="stable"
    else
      echo "You can only use one qualifier; choose 'stable' or 'nightly'."
      exit 1
    fi
    ;;
    *)
    echo "Unknown option: $i"
    exit 1
    ;;
esac
done

# Use stable by default
if [[ -z $kind ]]; then
  kind="stable"
fi

# Use ~/.local default prefix
if [[ -z $prefix ]]; then
  prefix=~/.local
fi

# FIXME: add option to override
tmp="/tmp"

# Require a tool to be selected
if [ ${#selected[@]} -eq 0 ]; then
  echo "Please specify a tool to install. To install all tools, use 'all'."
  exit 1
fi

# Create installation directories if necessary
if [ ! -d $prefix/bin ]; then
  echo "> Creating directory $prefix/bin"
  mkdir -p $prefix/bin;
fi

if [ ! -d $prefix/lib ]; then
  echo "> Creating directory $prefix/lib"
  mkdir -p $prefix/lib;
fi

echo $prefix
echo $kind
echo ${selected[0]}

for tool in "${selected[@]}"; do
  case $tool in
    cli)
      description="CLI tools"
      if [ "$kind" = "nightly" ]; then
        rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/tags/nightly"
        kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep download_url | grep Linux-aarch64.tar.gz)
      else
        rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/latest"
        kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep download_url | grep lf-cli-0.4.0.tar.gz)
      fi
      arr=($kvp)
      url="${arr[1]:1:-1}"
      file=$(echo $url | grep -o '[^/]*\.tar.gz')
      dir=$tmp/"${file%.tar.gz}"
    ;;
    *)
      echo "> Unable to install $tool."
      continue
    ;;
  esac

  echo "> Installing the latest $kind $description release of $tool..."
  echo ""

  # Download
  cleanup $tool
  echo "  * Downloading from $url"
  download $tool

  # Install and remove tmp files
  echo "  * Installing from $tmp into $prefix"
  install $tool
  echo "  * Removing temporary files"
  cleanup $tool

  echo ""
done

echo "> Done. Please ensure that $prefix/bin is on your PATH."
echo ""
