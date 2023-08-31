#!/bin/sh
set -eo pipefail

# Installer for Lingua Franca tools.
# 
# To install the stable CLI tools, run:
# curl -Ls https://install.lf-lang.org | bash -s cli
# To install the nightly CLI tools, run:
# curl -Ls https://install.lf-lang.org | bash -s nightly cli
#
# To install the stable release of Epoch, run:
# curl -Ls https://install.lf-lang.org | bash -s epoch
# To install the nightly release of Epoch, run:
# curl -Ls https://install.lf-lang.org | bash -s nightly epoch

tools=("cli" "epoch")
selected=()
timestamp=$(date '+%Y%m%d%H%M%S')

if [[ $(uname -m) == 'arm64' ]]; then
  arch='aarch64'
else
  arch='x86_64'
fi

sh_os="Linux"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  bin_os="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  bin_os="MacOS"
  sh_os="$bin_os"
elif [[ "$OSTYPE" == "msys" ]]; then
  bin_os="Windows"
else
  echo "Unsupported operating system: $OSTYPE"
fi

install() (
  case $1 in
    cli)
      if [[ "$bin_os" == "Windows" ]]; then
        echo "    - Installation on WSL is currently unsupported"
        echo "      => PowerShell scripts available at https://github.com/lf-lang/lingua-franca/releases"
      else
        mkdir -p $share/cli
        cp -rf $dir/* $share/cli
        ln -sf  $share/cli/bin/lfc $bin/lfc
        ln -sf  $share/cli/bin/lfd $bin/lfd
        ln -sf  $share/cli/bin/lff $bin/lff
        echo "    - Installed: $(ls -m $dir/bin/)"
      fi
    ;;
    epoch)
      if [[ "$bin_os" == "MacOS" ]]; then
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
 if [[ "$bin_os" == "MacOS" ]]; then
    prefix=/usr/local
  else
    prefix=~/.local
  fi
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
  echo "Please specify a tool to install. To install all tools, use 'all'."
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
      if [[ "$kind" = "nightly" ]]; then
        rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/tags/nightly"
        kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep download_url | grep $sh_os-$arch.tar.gz)
      else
        if [[ "$bin_os" == "Windows" ]]; then
          # FIXME: remove after release of v0.5.0
          echo "> Stable version of $tool currently unavailable for Windows."
          continue
        fi
        rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/latest"
        kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep download_url | grep lf-cli | grep tar.gz)
      fi
      arr=($kvp)
      url="${arr[1]//\"/}"
      file=$(echo $url | grep -o '[^/]*\.tar.gz')
      dir=$tmp/"${file%.tar.gz}"
    ;;
    epoch)
      description="Epoch IDE"
      if [[ "$bin_os" == "Windows" ]]; then
        os="win32"
      elif [[ "$bin_os" == "Linux" ]]; then
        os="linux"
      elif [[ "$bin_os" == "MacOS" ]]; then
        os="mac"
      fi
      if [[ "$kind" == "nightly" ]]; then
        rel="https://api.github.com/repos/lf-lang/epoch/releases/tags/nightly"
        kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep "download_url" | grep "$arch" | grep "$os")
      else
        if [[ "$bin_os" == "Windows" ]]; then
          # FIXME: remove after release of v0.5.0
          echo "> Stable version of $tool currently unavailable for Windows."
          continue
        fi
        rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/latest"
        kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep "download_url" | grep "epoch" | grep "$arch" | grep "$os")
      fi
      arr=($kvp)
      url="${arr[1]//\"/}"
      if [[ "$bin_os" == "MacOS" ]]; then
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

  echo "> Installing the latest $kind release of $description..."
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

echo "> Done. Please ensure that $bin is on your PATH."
echo ""
