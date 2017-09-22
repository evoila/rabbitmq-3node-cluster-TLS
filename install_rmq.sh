#! /bin/sh
export MASTERNODE=rmq-1
export RMQ_ADMIN=admin
export RMQ_PASSWORD=password

yum install wget -y
wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/create_ca_and_cert.sh
chmod +x create_ca_and_cert.sh
source ./create_ca_and_cert.sh
cp server/cert.pem /etc/rabbitmq/ssl/
cp server/key.pem /etc/rabbitmq/ssl/
cp ca/cacert.pem /etc/rabbitmq/ssl/
cat /etc/rabbitmq/ssl/cert.pem /etc/rabbitmq/ssl/key.pem > /etc/rabbitmq/ssl/inter-node.pem
yum install epel-release -y
wget https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
yum install erlang-19.3-1.el7.centos -y
yum install socat -y
wget https://bintray.com/rabbitmq/rabbitmq-server-rpm/download_file?file_path=rabbitmq-server-3.6.9-1.el6.noarch.rpm -O rmq.npm
rpm -ihv rmq.npm
systemctl stop firewalld
systemctl disable firewalld
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
mkdir /etc/rabbitmq/ssl
cp server/cert.pem /etc/rabbitmq/ssl/
cp server/key.pem /etc/rabbitmq/ssl/
cp ca/cacert.pem /etc/rabbitmq/ssl/
rabbitmqctl add_user $RMQ_ADMIN $RMQ_PASSWORD
rabbitmqctl set_user_tags $RMQ_ADMIN administrator
rabbitmqctl set_permissions -p / $RMQ_ADMIN ".*" ".*" ".*"
wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/rabbitmq.config -O /etc/rabbitmq/rabbitmq.config
wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/rabbitmq-env.conf  -O /etc/rabbitmq/rabbitmq-env.conf
chown rabbitmq:rabbitmq /etc/rabbitmq/* -R
systemctl restart rabbitmq-server
if [ "$MASTERNODE" == "$HOSTNAME" ]
    then
        
    else
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@$MASTERNODE
fi
rabbitmqctl set_policy ha-all “” ‘{“ha-mode”:“all”,“ha-sync-mode”:“automatic”}’
systemctl restart rabbitmq-server