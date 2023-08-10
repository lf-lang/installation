#!/bin/bash

# Installer for Lingua Franca CLI tools.
# 
# Usage: curl -s https://lf-lang.org/install-cli.sh | bash -s nightly

if [[ $1 == "nightly" ]]; then
  kind="nightly"
  rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/tags/nightly"
else
  kind="stable"
  rel="https://api.github.com/repos/lf-lang/lingua-franca/releases/latest"
fi

echo "Installing latest $kind Lingua Franca release..."
echo ""

# Determine download URL
kvp=$(curl -L -H "Accept: application/vnd.github+json" $rel 2>&1 | grep download_url | grep Linux-aarch64.tar.gz)
arr=($kvp)
url="${arr[1]:1:-1}"

# Download and unpack in /tmp
echo "> Downloading from $url"
echo "> Upacking into /tmp"
rm -rf /tmp/lf-cli*
curl -sL $url | tar xfz - -C /tmp #xz

# Create local installation directories if necessary
if [ ! -d ~/.local/bin ]; then
  mkdir -p ~/.local/bin;
fi

if [ ! -d ~/.local/lib ]; then
  mkdir -p ~/.local/lib;
fi

# Install and remove tmp files
echo "> Installing from /tmp into ~/.local"
cp -f /tmp/lf-cli*/bin/* ~/.local/bin/
cp -f /tmp/lf-cli*/lib/* ~/.local/lib/
echo "> Removing temporary files"
rm -rf /tmp/lf-cli*

# Add ~/.local/bin to PATH if necessary
echo "> Configuring PATH"
if echo $PATH | grep -q ~/.local/bin; then
  echo "  ~/.local/bin already found on PATH"
else
  echo "# Entry added as part of Lingua Franca CLI tools installation:" >> ~/.bashrc
  echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ~/.bashrc
  echo "  ...please open a new terminal or run 'source ~/.bashrc'"
fi

echo ""
echo "To verify that the installation was successful, run 'lfc --version'"