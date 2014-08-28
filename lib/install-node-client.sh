#!/bin/sh
############################################################
# Prey Unattended Installer
# Written by Tomas Pollak (tomas@forkhq.com)
# (c) 2013 Fork, Ltd.
############################################################

set -e # abort if any errors occur
abort() { echo $1 && exit 2; }

VERSION=$1
API_KEY=$2
DEV_KEY=$3

cwd="$(dirname $0)"
zip="${cwd}/package.zip"

[ -z "$VERSION" ] && abort 'Usage: install [version] ([api_key] [device_key])'

if [ "$(uname)" = 'WindowsNT' ]; then

  WIN=1
  BASE_PATH="${WINDIR}\Prey"
  CONFIG_DIR="$BASE_PATH"
  LOG_FILE="$BASE_PATH\prey.log"
  OLD_CLIENT="/c/Prey"
  OLD_CLIENT_TWO="/c/Windows/Prey"

else

  [ "$(whoami)" != 'root' ] && abort 'Must run as root.'
  PREY_USER="prey"
  BASE_PATH="/usr/lib/prey"
  CONFIG_DIR="/etc/prey"
  LOG_FILE="/var/log/prey.log"
  OLD_CLIENT="/usr/share/prey"

fi

RELEASES_URL="https://s3.amazonaws.com/prey-releases/node-client"
VERSIONS_PATH="${BASE_PATH}/versions"
INSTALL_PATH="${BASE_PATH}/versions/${VERSION}"
PREY_BIN="bin/prey"

############################################################
# helpers

log() {
  echo "$1"
}

lowercase() {
  echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

# echoes 1 if true
is_process_running() {
  'ps ax' | grep -v grep | grep "$1" > /dev/null && echo 1
}

############################################################
# cleanup logic

cleanup() {
  local code="$?"
  [ "$code" -eq 0 ] && return 0

  log "Upgrade failed! Exit code is ${code}. Cleaning up..."

  if [ ! -d "$INSTALL_PATH" ]; then # couldn't event put files into place

    # only remove base path if it wasn't previously there
    if [ -z "$existing_base_path" ]; then
      remove_all
    fi

  else
    cd "$INSTALL_PATH"
    log "Reverting installation!"

    # if a previous installation exited, this will remove the daemon scripts
    # so we should later run post_install on the previous version's path
    log "Running uninstallation hooks..."
    $PREY_BIN config hooks pre_uninstall 2> /dev/null

    if [ -n "$WIN" ]; then
      # make sure no prey-config instances are there
      TASKKILL //F //IM prey-config.exe //T &> /dev/null || true
    fi

    cd "$cwd"

    if [ -n "$existing_base_path" ]; then
      log "Removing version path: ${INSTALL_PATH}"
      rm -Rf "$INSTALL_PATH"

      if [ -n "$installation_activated" ]; then
        if [ -d "$previous_active_version" ]; then
          log "Reverting to previous active version..."

          # symlink and put daemon scripts back in place
          post_install "$previous_active_version"
        else
          remove_all
        fi
      fi
    else
      log "No previous versions detected. Removing base path."
      remove_all
    fi
  fi

  # remove trap, and exit again
  # trap - EXIT
  # exit $code
}

remove_all() {
  if [ -n "$user_created" ]; then
    log "Deleting user ${PREY_USER}..."
    userdel "$PREY_USER"
  fi

  log "Removing path: ${BASE_PATH}"
  rm -Rf "$BASE_PATH"
}

############################################################
# existing versions

check_installed() {
  if [ -d "$BASE_PATH" ]; then
    log "Previous installation detected."
    existing_base_path=1

    if [ -d "$INSTALL_PATH" ]; then
      log "Matching version found in ${INSTALL_PATH}! Nothing to do."
      exit 0 # exit with code 0 so no directories are removed.
    else
      if [ -f "${BASE_PATH}/current/package.json" ]; then
        local ver=$(grep version "${BASE_PATH}/current/package.json" | sed "s/[^0-9\.]//g")
        if [ -d "${BASE_PATH}/versions/${ver}" ]; then
          previous_active_version="${BASE_PATH}/versions/${ver}"
          log "Previous active version found: ${previous_active_version}"
        fi
      fi
      log "Installing new version."
    fi
  fi
}

remove_previous() {

  log "Checking for previous installed versions..."

  if [ -n "$WIN" ]; then

    if [ -d "$OLD_CLIENT" ]; then
      run_windows_uninstaller "$OLD_CLIENT"
    elif [ -d "$OLD_CLIENT_TWO" ]; then
      run_windows_uninstaller "$OLD_CLIENT_TWO"
    fi

  else

    if [ -d "$OLD_CLIENT" ]; then
      log "Previous installation found. Removing..."
      rm -Rf "$OLD_CLIENT"

      # make sure that no crontabs remain for sudo or the prey user (linux)
      (sudo crontab -l | grep -v prey.sh || true) | sudo crontab -
      (sudo crontab -u prey -l | grep -v prey.sh || true) | sudo -u prey crontab -
    fi

    # check if network trigger script exists
    if [ -f "/etc/init.d/prey-trigger" ]; then
      "/etc/init.d/prey-trigger" stop || true
      update-rc.d -f prey-trigger remove > /dev/null || true
      rm -f "/etc/init.d/prey-trigger" || true
    fi

  fi

}

run_windows_uninstaller() {

  local path="$1"
  log "Old Prey client found in ${path}! Removing..."

  # even if run in silent mode, the NSIS uninstall will show the prompt screen
  # so we just need to clean up the registry keys and remove the files.

  # if the new install was successful, the old CronService should have been
  # replaced with the new one (the one that calls node.exe and the new client)
  # there's nothing else to do there

  # TASKKILL //F //IM cronsvc.exe //T &> /dev/null

  # if [ -f "${path}/Uninstall.exe" ]; then
  #   "${path}/Uninstall.exe" /S _?="$path"
  # elif [ -f "${path}/platform/windows/Uninstall.exe" ]; then
  #   "${path}/platform/windows/Uninstall.exe" /S _?="$path"
  # fi

  # reg delete "HKLM\Software\Prey" //f

  rm -Rf "$path" || true
}

############################################################
# download, unpack

get_latest_version() {
  log "Determining latest version..."
  local ver="$(curl "${RELEASES_URL}/latest.txt" 2> /dev/null)"
  [ $? -ne 0 ] && return 1

  # rewrite variables
  VERSION="$ver"
  INSTALL_PATH="${BASE_PATH}/versions/${VERSION}"
}

determine_file() {
  local ver="$1"
  local cpu="$(uname -m)"

  if [ -n "$WIN" ]; then
    local os="windows"
  else
    local os=$(lowercase $(uname))
    [ "$os" = "darwin" ] && os="mac"
  fi

  if [ "$cpu" = "x86_64" ]; then
    local arch="x64"
  else
    local arch="x86"
  fi

  echo "prey-${os}-${ver}-${arch}.zip"
}

download_zip() {
  local ver="$1"
  local out="$2"

  local file=$(determine_file $ver)
  local url="${RELEASES_URL}/${ver}/${file}"

  log "Downloading ${url}"
  curl -s "$url" -o "$out"
  return $?
}

unpack_file() {
  local file="$1"

  log "Unpacking ${file} into ${VERSIONS_PATH}..."
  mkdir -p "$VERSIONS_PATH"
  unzip "$file" -d "$VERSIONS_PATH" 1> /dev/null
  [ $? -ne 0 ] && return 1

  rm -f "$file"

  cd "$VERSIONS_PATH"
  mv prey-${VERSION} $VERSION
}

############################################################
# when files are in place

create_user() {
  [ -z "$PREY_USER" ] && return 1

  local script="$INSTALL_PATH/scripts/create_user.sh"

  if [ -f "$script" ]; then
    id $PREY_USER &> /dev/null
    [ $? -ne 0 ] && user_created=1 # for checking on cleanup

    log "Creating local '${PREY_USER}' user..."
    "$script" $PREY_USER || true
  fi
}

set_permissions() {
  log "Setting up permissions..."
  mkdir -p "$CONFIG_DIR"
  touch "$LOG_FILE"

  if [ -z "$WIN" ]; then # set up permissions
    chown -R $PREY_USER: "$CONFIG_DIR" "$BASE_PATH" "$LOG_FILE"
  fi
}

activate() {
  local path="$1"
  cd "$path"
  installation_activated=1 # for cleanup

  if [ -z "$WIN" ]; then
    # as user, symlinks and generates prey.conf
    su $PREY_USER -c "$PREY_BIN config activate"
  else
    log "Activating installation..."
    local activate_out=$($PREY_BIN config activate)
    log "Activation returned with code $?"
  fi
}

start_service() {
  local path="$1"
  cd "$path"

  if [ -n "$WIN" ]; then
    # now make sure mmc.exe and taskmgr.exe are not running
    # otherwise the existing service won't be removed
    TASKKILL //F //IM mmc.exe //T &> /dev/null || true
    TASKKILL //F //IM taskmgr.exe //T &> /dev/null || true
  fi

  # as root, admin, sets up launch/init/service
  log "Running post-install tasks..."
  local postinst_out=$($PREY_BIN config hooks post_install)
  log "Post install tasks returned with code $?"
}

post_install() {
  activate "$1"
  start_service "$1"
}

update_registry_keys() {
  log "Updating registry keys..."
  reg add "HKLM\Software\Prey" //v "INSTALLDIR" //d "$BASE_PATH" //f &> /dev/null || true
  reg delete "HKLM\Software\Prey" //v "Path" //f &> /dev/null || true
  reg delete "HKLM\Software\Prey" //v "Delay" //f &> /dev/null || true
}

setup_account() {
  cd "$INSTALL_PATH"

  if [ -z "$API_KEY" ]; then
    log "Firing up GUI..."
    $PREY_BIN config gui
  elif [ -n "$(echo "$API_KEY" | grep "@")" ]; then # email/pass
    log "Authorizing user credentials..."
    $PREY_BIN config account authorize -e $API_KEY -p $DEV_KEY
  else # api_key/device_key
    log "Validating keys..."
    $PREY_BIN config account verify -a $API_KEY -d $DEV_KEY -u
  fi

  log "Account setup returned with code $?"
}

############################################################
# the main course

trap cleanup EXIT # INT

if [ ! -f "$zip" ]; then

  [ "$VERSION" = 'latest' ] && get_latest_version
  [ $? -ne 0 ] && abort "Unable to determine latest version."

  check_installed
  log "Installing version ${VERSION} to ${BASE_PATH}"

  download_zip "$VERSION" "$zip"
  [ $? -ne 0 ] && abort 'Unable to download file.'

fi

unpack_file "$zip"

[ -z "$WIN" ] && create_user

set_permissions
post_install "$INSTALL_PATH"
setup_account

if [ -n "$WIN" ]; then
  update_registry_keys

  if [ -z "$(is_process_running 'node.exe')" ]; then
    log "Looks like the process failed to start."
    start_service "$INSTALL_PATH"
  fi
fi

remove_previous

# cd "$cwd"
log "All done."
exit 0
