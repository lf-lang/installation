#!/bin/sh
set -eo pipefail

# Docs: https://github.com/lf-lang/installation
# Author: marten@berkeley.edu
# License: BSD-2

tools=("cli" "epoch")
selected=()
timestamp=$(date '+%Y%m%d%H%M%S')

if [[ $(uname -m) == 'arm64' ]]; then
  arch='aarch64'
else
  arch='x86_64'
fi

if [[ "$OSTYPE" == "linux"* ]]; then
  os="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  os="MacOS"
else
  echo "Error: Unsupported operating system: $OSTYPE" >&2
  exit 1
fi

install() (
  case $1 in
    cli)
      mkdir -p $share/cli
      cp -rf $dir/* $share/cli
      ln -sf  $share/cli/bin/lfc $bin/lfc
      ln -sf  $share/cli/bin/lfd $bin/lfd
      ln -sf  $share/cli/bin/lff $bin/lff
      echo "    - Installed: $(ls -m $dir/bin/)"
    ;;
    epoch)
      if [[ "$os" == "MacOS" ]]; then
        cp -rf $dir /Applications/
        xattr -cr /Applications/Epoch.app
        rm -rf $prefix/bin/epoch
        touch $bin/epoch
        chmod +x $bin/epoch
        echo '#!/bin/bash' > $bin/epoch
        echo 'open /Applications/Epoch.app --args $@' >> $bin/epoch
      else
        cp -rf $dir $share/
        ln -sf $share/epoch/epoch $bin/epoch
      fi
      echo "    - Installed: epoch"
    ;;
  esac
  
)

cleanup() (
  case $1 in
    cli|epoch)
      rm -rf $dir
    ;;
  esac
)

download() (
  echo "    - Downloading and unpacking into $dir"
  mkdir -p $tmp
  if [[ "$url" =~ .*tar\.gz$ ]];then
    curl -L --progress-bar $url | tar xfz - -C $tmp
  elif [[ "$url" =~ .*zip$ ]];then
    file="$tmp/lf-install-$timestamp.zip"
    curl -L --progress-bar $url -o $file
    unzip -qq -d $tmp $file
    rm -rf $file
  else
    echo "Unsuccessful. Unrecognized file format."
  fi
)

# Parse arguments
for i in "$@"
do
case $i in
    -v|--version)
    echo "install.sh $version"
    exit 0
    ;;
    -p=*|--prefix=*)
    prefix=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    -t=*|--temporary=*)
    tmp=`echo $i | sed 's/[-a-zA-Z0-9]*=//'`
    ;;
    all)
    selected=("${tools[@]}")
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
      echo "Error: You can only use one qualifier; choose 'stable' or 'nightly'" >&2
      exit 1
    fi
    ;;
    stable)
    if [[ -z $kind ]]; then
      kind="latest"
    else
      echo "Error: You can only use one qualifier; choose 'stable' or 'nightly'"
      exit 1
    fi
    ;;
    v[0-9]*.[0-9]*.[0-9]*|[0-9]*.[0-9]*.[0-9]*)
    if [[ -n $kind ]]; then
      echo "Error: Either use a version number or a qualifier ('stable' or 'nightly'), not both" >&2
      exit 1
    fi
    version=${i#v}
    supported="^(0\.([5-9][0-9]*|[1-9][0-9]+)\.[0-9]+)|(([1-9][0-9]*)\.[0-9]+\.[0-9]+)$"
    if ! [[ $version =~ $supported ]]; then
      echo "Error: Only versions 0.5.0 and up can be installed using this script" >&2
      exit 1
    fi
    ;;
    *)
    echo "Error: Unknown option: $i"
    exit 1
    ;;
esac
done

# Either use the supplied version, nightly, or latest.
if [[ -n $version ]]; then
  suffix="tags/v${version}"
else
  if [[ "$kind" == "nightly" ]]; then
    suffix="tags/nightly"
  else
    suffix="latest"
  fi
fi

# Use ~/.local default prefix
if [[ -z $prefix ]]; then
  prefix=~/.local
fi

# Use /tmp as the default temporary storage
if [[ -z $tmp ]]; then
  tmp="/tmp/lingua-franca"
else
  tmp="${tmp%/}/lingua-franca"
fi

share="$prefix/share/lingua-franca"
bin="$prefix/bin"

# Require a tool to be selected
if [ ${#selected[@]} -eq 0 ]; then
  echo "Error: Please specify a tool to install. To install all tools, use 'all'." >&2
  exit 1
fi

# Create installation directories if necessary
if [ ! -d $bin ]; then
  echo "> Creating directory $bin"
  mkdir -p $bin;
fi

if [ ! -d $share ]; then
  echo "> Creating directory $share"
  mkdir -p $share;
fi

# Install the selected tools
for tool in "${selected[@]}"; do
  case $tool in
    cli)
      description="CLI tools"
      rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/$suffix"
      kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep download_url | grep $os-$arch.tar.gz)
      arr=($kvp)
      url="${arr[1]//\"/}"
      file=$(echo $url | grep -o '[^/]*\.tar.gz')
      dir=$tmp/"${file%.tar.gz}"
    ;;
    epoch)
      description="Epoch IDE"
      if [[ "$os" == "Linux" ]]; then
        os_abbr="linux"
      elif [[ "$os" == "MacOS" ]]; then
        os_abbr="mac"
      fi
      rel="https://api.github.com/repos/lf-lang/epoch/releases/$suffix"
      kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep "download_url" | grep "$arch" | grep "$os_abbr")
      arr=($kvp)
      url="${arr[1]//\"/}"
      if [[ "$os" == "MacOS" ]]; then
        dir="$tmp/epoch.app"
      else
        dir="$tmp/epoch"
      fi
    ;;
    *)
      echo "> Unable to install $tool."
      continue
    ;;
  esac

  echo "> Installing the ${kind:-$version} release for $os-$arch of $description..."

  # Download
  cleanup $tool
  echo "  * Downloading from $url"
  download $tool

  # Install and remove tmp files
  echo "  * Installing from $tmp into $prefix"
  install $tool
  echo "  * Removing temporary files"
  cleanup $tool
done

echo "> Done. Please ensure that $bin is on your PATH."
echo ""
