#!/bin/bash

# Fetch the latest preview version from the Godot builds repository
LATEST_VERSION=$(curl -s https://api.github.com/repos/godotengine/godot-builds/releases | jq -r '.[] | select(.prerelease == true) | .tag_name' | head -n 1)

# Check if a version was found
if [ -z "$LATEST_VERSION" ]; then
  echo "No preview version found."
  exit 1
fi

echo "Latest preview version found: $LATEST_VERSION"

# Create the installation directory
INSTALL_DIR="./godot"
BASE_FILENAME="Godot_v${LATEST_VERSION//_/.}_mono_linux_x86_64"
EXECUTABLE_NAME="Godot_v${LATEST_VERSION//_/.}_mono_linux.x86_64"  # Correct executable name without extension
EXECUTABLE_DIR="$INSTALL_DIR/$BASE_FILENAME"  # Directory where the files are extracted

# Debug output
echo "Executable Directory: $EXECUTABLE_DIR"
echo "Executable Name: $EXECUTABLE_NAME"

# Check if the specific version is already installed
if [ -d "$EXECUTABLE_DIR" ]; then
  echo "Version $LATEST_VERSION already exists locally. Skipping download."
else
  # Fetch the latest release data to inspect asset names
  RELEASE_DATA=$(curl -s https://api.github.com/repos/godotengine/godot-builds/releases)

  # Find the Mono asset URL for the correct build
  ASSET_URL=$(echo "$RELEASE_DATA" | jq -r '.[] | select(.tag_name == "'"$LATEST_VERSION"'") | .assets[] | select(.name == "Godot_v'"$LATEST_VERSION"'_mono_linux_x86_64.zip") | .url')

  # Check if ASSET_URL is empty
  if [ -z "$ASSET_URL" ]; then
    echo "Mono build asset not found for version: $LATEST_VERSION"
    echo "Available assets for version $LATEST_VERSION:"
    echo "$RELEASE_DATA" | jq -r '.[] | select(.tag_name == "'"$LATEST_VERSION"'") | .assets[].name'
    exit 1
  fi

  echo "Downloading from: $ASSET_URL"

  # Use curl to download the file
  curl -L -o "godot-${LATEST_VERSION}-mono-linux-x86_64.zip" -H "Accept: application/octet-stream" "$ASSET_URL"

  # Check if the download was successful
  if [ ! -f "godot-${LATEST_VERSION}-mono-linux-x86_64.zip" ]; then
    echo "Download failed."
    exit 1
  fi

  # Unzip the downloaded file to the installation directory
  unzip "godot-${LATEST_VERSION}-mono-linux-x86_64.zip" -d "$INSTALL_DIR"

  # Clean up
  rm "godot-${LATEST_VERSION}-mono-linux-x86_64.zip"
fi

# Ensure the executable directory exists
mkdir -p "$EXECUTABLE_DIR"

# Create or update the symlink for the executable
ln -sf "$BASE_FILENAME/$EXECUTABLE_NAME" "$INSTALL_DIR/godot"

# Ensure the Godot executable is executable
chmod +x "$EXECUTABLE_DIR/$EXECUTABLE_NAME"

echo "Symlink created/updated: $INSTALL_DIR/godot"
