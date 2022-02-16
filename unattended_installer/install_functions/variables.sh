## Package vars
readonly wazuh_major="4.3"
readonly wazuh_version="4.3.0"
readonly wazuh_revision="1"
readonly filebeat_version="7.10.2"
readonly opendistro_version="1.13.2"
readonly opendistro_revision="1"
readonly wazuh_install_vesion="0.1"

## Links and paths to resources
readonly functions_path="install_functions"
readonly config_path="config"
readonly resources="https://packages-dev.wazuh.com/resources/${wazuh_major}"
readonly resources_functions="${resources}/${functions_path}"
readonly resources_config="${resources}/${config_path}"
readonly base_path="$(dirname $(readlink -f "$0"))"
readonly config_file="${base_path}/config.yml"
readonly tar_file="${base_path}/configurations.tar"

readonly filebeat_wazuh_template="https://raw.githubusercontent.com/wazuh/wazuh/${wazuh_major}/extensions/elasticsearch/7.x/wazuh-template.json"

repogpg="https://packages.wazuh.com/key/GPG-KEY-WAZUH"
repobaseurl="https://packages.wazuh.com/4.x"
reporelease="stable"
filebeat_wazuh_module="${repobaseurl}/filebeat/wazuh-filebeat-0.1.tar.gz"

readonly dashboard_cert_path="/etc/wazuh-dashboard/certs/"
readonly filebeat_cert_path="/etc/filebeat/certs/"
readonly indexer_certs_path="/etc/wazuh-indexer/certs/"

readonly logfile="/var/log/wazuh-unattended-installation.log"
debug=">> ${logfile} 2>&1"