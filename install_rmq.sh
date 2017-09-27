#! /bin/sh
export RMQ_ADMIN=admin
#echo "Please enter the Password for the RabbitMQ admin" 
#read -sr RMQ_PASSWORD_INPUT
#export RMQ_PASSWORD=$RMQ_PASSWORD_INPUT
export RMQ_PASSWORD=password
#echo "Do you want to deploy a RabbitMQ Cluster node?(yes/no)" 
export RMQCLUSTER=true
yum install wget -y
yum install epel-release -y
wget https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
yum install erlang-19.3-1.el7.centos -y
yum install socat -y
wget https://bintray.com/rabbitmq/rabbitmq-server-rpm/download_file?file_path=rabbitmq-server-3.6.9-1.el6.noarch.rpm -O rmq.npm
rpm -ihv rmq.npm
rabbitmq-plugins enable rabbitmq_management
systemctl restart rabbitmq-server
rabbitmqctl add_user $RMQ_ADMIN $RMQ_PASSWORD
rabbitmqctl set_user_tags $RMQ_ADMIN administrator
rabbitmqctl set_permissions -p / $RMQ_ADMIN ".*" ".*" ".*"
wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/rabbitmq.config -O /etc/rabbitmq/rabbitmq.config
wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/rabbitmq-env.conf  -O /etc/rabbitmq/rabbitmq-env.conf
if [ "$MASTERNODE" == "$HOSTNAME" ]
    then
        wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/create_ca_and_cert.sh
        chmod +x create_ca_and_cert.sh
        ./create_ca_and_cert.sh
        mkdir /etc/rabbitmq/ssl /usr/share/ssl/
        cp server/cert.pem /usr/share/ssl/
        cp server/key.pem /usr/share/ssl/
        cp ca/cacert.pem /usr/share/ssl/
        cp server/cert.pem /etc/rabbitmq/ssl/
        cp server/key.pem /etc/rabbitmq/ssl/
        cp ca/cacert.pem /etc/rabbitmq/ssl/
        cat /etc/rabbitmq/ssl/cert.pem /etc/rabbitmq/ssl/key.pem > /etc/rabbitmq/ssl/inter-node.pem
fi
if [ "$RMQCLUSTER" == "true" ]
then
    wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/join_cluster.sh -O /etc/rabbitmq/join_cluster.sh
    chmod +x /etc/rabbitmq/join_cluster.sh
    chmod 777 /etc/rabbitmq/join_cluster.sh
    echo "source /etc/rabbitmq/join_cluster.sh" >> /etc/rc.d/rc.local
    chown rabbitmq:rabbitmq /etc/rabbitmq/* -R
    chmod +x /etc/rc.d/rc.local
    reboot
    
else
    wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/create_ca_and_cert.sh
    chmod +x create_ca_and_cert.sh
    source ./create_ca_and_cert.sh
    mkdir /etc/rabbitmq/ssl 
    cp server/cert.pem /etc/rabbitmq/ssl/
    cp server/key.pem /etc/rabbitmq/ssl/
    cp ca/cacert.pem /etc/rabbitmq/ssl/
fi