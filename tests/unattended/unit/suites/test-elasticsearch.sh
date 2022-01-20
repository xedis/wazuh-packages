#!/usr/bin/env bash
set -euo pipefail
base_dir="$(cd "$(dirname "$BASH_SOURCE")"; pwd -P; cd - >/dev/null;)"
source "${base_dir}"/bach.sh

@setup-test {
    @ignore logger
    e_certs_path="/etc/elasticsearch/certs/"
    # wazuh_version="4.3.0"
    # elasticsearch_oss_version="7.10.2"
    # wazuh_kibana_plugin_revision="1"
    # repobaseurl="https://packages.wazuh.com/4.x"
    # kibana_wazuh_plugin="${repobaseurl}/ui/kibana/wazuh_kibana-${wazuh_version}_${elasticsearch_oss_version}-${wazuh_kibana_plugin_revision}.zip"
}

function load-copyCertificatesElasticsearch() {
    @load_function "${base_dir}/elasticsearch.sh" copyCertificatesElasticsearch
}

test-ASSERT-FAIL-copyCertificatesElasticsearch-no-tarfile() {
    load-copyCertificatesElasticsearch
    tar_file=/tmp/tarfile.tar
    if [ -f ${tar_file} ]; then
        @rm ${tar_file}
    fi
    copyCertificatesElasticsearch
}

test-copyCertificatesElasticsearch() {
    load-copyCertificatesElasticsearch
    tar_file=/tmp/tarfile.tar
    @touch ${tar_file}
    pos=0
    elasticsearch_node_names=("elastic1" "elastic2")
    debug=
    copyCertificatesElasticsearch
}

test-copyCertificatesElasticsearch-assert() {
    tar -xf /tmp/tarfile.tar -C /etc/elasticsearch/certs/ ./elastic1.pem  && mv /etc/elasticsearch/certs/elastic1.pem /etc/elasticsearch/certs/elasticsearch.pem
    tar -xf /tmp/tarfile.tar -C /etc/elasticsearch/certs/ ./elastic1-key.pem  && mv /etc/elasticsearch/certs/elastic1-key.pem /etc/elasticsearch/certs/elasticsearch-key.pem
    tar -xf /tmp/tarfile.tar -C /etc/elasticsearch/certs/ ./root-ca.pem
    tar -xf /tmp/tarfile.tar -C /etc/elasticsearch/certs/ ./admin.pem
    tar -xf /tmp/tarfile.tar -C /etc/elasticsearch/certs/ ./admin-key.pem
}

function load-installElasticsearch() {
    @load_function "${base_dir}/elasticsearch.sh" installElasticsearch
}

test-installElasticsearch-zypper() {
    load-installElasticsearch
    sys_type="zypper"
    opendistro_version="1.13.2"
    opendistro_revision="1"
    installElasticsearch
}

test-installElasticsearch-zypper-assert() {
    zypper -n install opendistroforelasticsearch=1.13.2-1
}

test-ASSERT-FAIL-installElasticsearch-zypper-error() {
    load-installElasticsearch
    sys_type="zypper"
    opendistro_version="1.13.2"
    opendistro_revision="1"
    @mockfalse zypper -n install opendistroforelasticsearch=1.13.2-1
    installElasticsearch
}

test-installElasticsearch-yum() {
    load-installElasticsearch
    sys_type="yum"
    sep="-"
    opendistro_version="1.13.2"
    opendistro_revision="1"
    installElasticsearch
}

test-installElasticsearch-yum-assert() {
    yum install opendistroforelasticsearch-1.13.2-1 -y
}

test-ASSERT-FAIL-installElasticsearch-yum-error() {
    load-installElasticsearch
    sys_type="yum"
    sep="-"
    opendistro_version="1.13.2"
    opendistro_revision="1"
    @mockfalse yum install opendistroforelasticsearch-1.13.2-1 -y 
    installElasticsearch
}

test-installElasticsearch-apt() {
    load-installElasticsearch
    sys_type="apt-get"
    sep="="
    opendistro_version="1.13.2"
    opendistro_revision="1"
    installElasticsearch
}

test-installElasticsearch-apt-assert() {
    apt install elasticsearch-oss opendistroforelasticsearch -y 
}

test-ASSERT-FAIL-installElasticsearch-apt-error() {
    load-installElasticsearch
    sys_type="apt-get"
    sep="="
    opendistro_version="1.13.2"
    opendistro_revision="1"
    @mockfalse apt install elasticsearch-oss opendistroforelasticsearch -y 
    installElasticsearch
}

function load-configureElasticsearch() {
    @load_function "${base_dir}/elasticsearch.sh" configureElasticsearch
}

test-configureElasticsearch-dist-one-elastic-node() {
    load-configureElasticsearch
    elasticsearch_node_names=("elastic1")
    elasticsearch_node_ips=("1.1.1.1")
    @mocktrue free -g
    @mocktrue awk '/^Mem:/{print $2}'
    @mock java -version === @out
    @mock grep -o -m1 '1.8.0' === @out 1.8.0
    einame="elastic1"
    configureElasticsearch
}


test-configureElasticsearch-dist-one-elastic-node-assert() {
    getConfig elasticsearch/elasticsearch_unattended_distributed.yml /etc/elasticsearch/elasticsearch.yml
    getConfig elasticsearch/roles/roles.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles.yml
    getConfig elasticsearch/roles/roles_mapping.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles_mapping.yml
    getConfig elasticsearch/roles/internal_users.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml

    rm /etc/elasticsearch/esnode-key.pem /etc/elasticsearch/esnode.pem /etc/elasticsearch/kirk-key.pem /etc/elasticsearch/kirk.pem /etc/elasticsearch/root-ca.pem -f
    mkdir /etc/elasticsearch/certs

    sed -i "s/-Xms1g/-Xms1g/" /etc/elasticsearch/jvm.options
    sed -i "s/-Xmx1g/-Xmx1g/" /etc/elasticsearch/jvm.options

    applyLog4j2Mitigation

    copyCertificatesElasticsearch

    rm /etc/elasticsearch/certs/client-certificates.readme /etc/elasticsearch/certs/elasticsearch_elasticsearch_config_snippet.yml -f
    /usr/share/elasticsearch/bin/elasticsearch-plugin remove opendistro-performance-analyzer

}

test-configureElasticsearch-dist-two-elastic-nodes() {
    load-configureElasticsearch
    elasticsearch_node_names=("elastic1" "elastic2")
    elasticsearch_node_ips=("1.1.1.1", "1.1.2.2")
    @mock free -g === @out "1"
    @mocktrue awk '/^Mem:/{print $2}'
    @mock java -version === @out
    @mock grep -o -m1 '1.8.0' === @out 1.8.0
    einame="elastic2"
    configureElasticsearch
}


test-configureElasticsearch-dist-two-elastic-nodes-assert() {
    getConfig elasticsearch/elasticsearch_unattended_distributed.yml /etc/elasticsearch/elasticsearch.yml
    getConfig elasticsearch/roles/roles.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles.yml
    getConfig elasticsearch/roles/roles_mapping.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles_mapping.yml
    getConfig elasticsearch/roles/internal_users.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml

    rm /etc/elasticsearch/esnode-key.pem /etc/elasticsearch/esnode.pem /etc/elasticsearch/kirk-key.pem /etc/elasticsearch/kirk.pem /etc/elasticsearch/root-ca.pem -f
    mkdir /etc/elasticsearch/certs

    sed -i "s/-Xms1g/-Xms1g/" /etc/elasticsearch/jvm.options
    sed -i "s/-Xmx1g/-Xmx1g/" /etc/elasticsearch/jvm.options

    applyLog4j2Mitigation

    copyCertificatesElasticsearch

    rm /etc/elasticsearch/certs/client-certificates.readme /etc/elasticsearch/certs/elasticsearch_elasticsearch_config_snippet.yml -f
    /usr/share/elasticsearch/bin/elasticsearch-plugin remove opendistro-performance-analyzer
}

function load-configureElasticsearchAIO() {
    @load_function "${base_dir}/elasticsearch.sh" configureElasticsearchAIO
}

test-configureElasticsearch-AIO() {
    load-configureElasticsearchAIO
    elasticsearch_node_names=("elastic1")
    elasticsearch_node_ips=("1.1.1.1")
    @mock free -g === @out "1"
    @mocktrue awk '/^Mem:/{print $2}'
    configureElasticsearchAIO
}


test-configureElasticsearch-AIO-assert() {
    getConfig elasticsearch/elasticsearch_all_in_one.yml /etc/elasticsearch/elasticsearch.yml
    getConfig elasticsearch/roles/roles.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles.yml
    getConfig elasticsearch/roles/roles_mapping.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/roles_mapping.yml
    getConfig elasticsearch/roles/internal_users.yml /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/internal_users.yml
    
    export JAVA_HOME=/usr/share/elasticsearch/jdk/
    rm /etc/elasticsearch/esnode-key.pem /etc/elasticsearch/esnode.pem /etc/elasticsearch/kirk-key.pem /etc/elasticsearch/kirk.pem /etc/elasticsearch/root-ca.pem -f

    mkdir /etc/elasticsearch/certs/
    copyCertificatesElasticsearch

    sed -i 's/-Xms1g/-Xms1g/' /etc/elasticsearch/jvm.options
    sed -i 's/-Xmx1g/-Xmx1g/' /etc/elasticsearch/jvm.options

    applyLog4j2Mitigation
}

function load-initializeElasticsearch() {
    @load_function "${base_dir}/elasticsearch.sh" initializeElasticsearch
}

test-initializeElasticsearch-one-node() {
    load-initializeElasticsearch
    elasticsearch_node_names=("elastic1")
    elasticsearch_node_ips=("1.1.1.1")
    pos=0
    @mocktrue curl -XGET https://1.1.1.1:9200/ -uadmin:admin -k --max-time 120 --silent --output /dev/null
    initializeElasticsearch
    @echo ${start_elastic_cluster}
}

test-initializeElasticsearch-one-node-assert() {
    startElasticsearchCluster
    changePasswords
    @echo 1
}

test-initializeElasticsearch-two-nodes() {
    load-initializeElasticsearch
    elasticsearch_node_names=("elastic1" "elastic2")
    elasticsearch_node_ips=("1.1.1.1" "1.1.2.2")
    pos=1
    @mocktrue curl -XGET https://1.1.2.2:9200/ -uadmin:admin -k --max-time 120 --silent --output /dev/null
    initializeElasticsearch
    @assert-success
}

test-ASSERT-FAIL-initializeElasticsearch-error-connecting() {
    load-initializeElasticsearch
    elasticsearch_node_names=("elastic1")
    elasticsearch_node_ips=("1.1.1.1")
    pos=0
    @mockfalse curl -XGET https://1.1.1.1:9200/ -uadmin:admin -k --max-time 120 --silent --output /dev/null
    initializeElasticsearch
}

function load-applyLog4j2Mitigation() {
    @load_function "${base_dir}/elasticsearch.sh" applyLog4j2Mitigation
}

test-applyLog4j2Mitigation() {
    load-applyLog4j2Mitigation
    applyLog4j2Mitigation
}

test-applyLog4j2Mitigation-assert() {
    curl -so /tmp/apache-log4j-2.17.1-bin.tar.gz https://packages.wazuh.com/utils/log4j/apache-log4j-2.17.1-bin.tar.gz
    tar -xf /tmp/apache-log4j-2.17.1-bin.tar.gz -C /tmp/

    cp /tmp/apache-log4j-2.17.1-bin/log4j-api-2.17.1.jar /usr/share/elasticsearch/lib/
    cp /tmp/apache-log4j-2.17.1-bin/log4j-core-2.17.1.jar /usr/share/elasticsearch/lib/
    cp /tmp/apache-log4j-2.17.1-bin/log4j-slf4j-impl-2.17.1.jar /usr/share/elasticsearch/plugins/opendistro_security/
    cp /tmp/apache-log4j-2.17.1-bin/log4j-api-2.17.1.jar /usr/share/elasticsearch/performance-analyzer-rca/lib/
    cp /tmp/apache-log4j-2.17.1-bin/log4j-core-2.17.1.jar /usr/share/elasticsearch/performance-analyzer-rca/lib/

    rm -f /usr/share/elasticsearch/lib//log4j-api-2.11.1.jar
    rm -f /usr/share/elasticsearch/lib/log4j-core-2.11.1.jar
    rm -f /usr/share/elasticsearch/plugins/opendistro_security/log4j-slf4j-impl-2.11.1.jar
    rm -f /usr/share/elasticsearch/performance-analyzer-rca/lib/log4j-api-2.13.0.jar
    rm -f /usr/share/elasticsearch/performance-analyzer-rca/lib/log4j-core-2.13.0.jar

    rm -rf /tmp/apache-log4j-2.17.1-bin
    rm -f /tmp/apache-log4j-2.17.1-bin.tar.gz
}
