#!/bin/bash

PACKAGES_REPOSITORY=$1
DEBUG=$2

RESOURCES_PATH="/tmp/unattended_installer"
BUILDER="builder.sh"
INSTALLER="wazuh-install.sh"
SYSTEM_USER="wazuh-user"
HOSTNAME="wazuh-manager"

CURRENT_PATH="$( cd $(dirname $0) ; pwd -P )"
ASSETS_PATH="${CURRENT_PATH}/assets"
CUSTOM_PATH="${ASSETS_PATH}/custom"
BUILDER_ARGS="-i"
INSTALL_ARGS="-a -ds"

if [[ "${PACKAGES_REPOSITORY}" == "dev" ]]; then
  BUILDER_ARGS+=" -d"
fi

if [[ "${DEBUG}" = "yes" ]]; then
  set -ex
  INSTALL_ARGS+=" -v"
else
  set -e
fi

echo "Using ${PACKAGES_REPOSITORY} packages"

. ${ASSETS_PATH}/steps.sh

# Buil install script
bash ${RESOURCES_PATH}/${BUILDER} ${BUILDER_ARGS}
WAZUH_VERSION=$(cat ${RESOURCES_PATH}/${INSTALLER} | grep "wazuh_version=" | cut -d "\"" -f 2)

# System configuration
systemConfig

# Edit installation script
preInstall

# Install
bash ${RESOURCES_PATH}/${INSTALLER} ${INSTALL_ARGS}

systemctl stop wazuh-dashboard filebeat wazuh-indexer
systemctl enable wazuh-manager

clean
