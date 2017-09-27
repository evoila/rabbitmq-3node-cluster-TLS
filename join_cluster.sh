export MASTERNODE=rmq-1
if [ "$MASTERNODE" == "$HOSTNAME" ]
    then
        wget https://raw.githubusercontent.com/evoila/vcd-rabbitmq-cluster-config/master/create_ca_and_cert.sh
        chmod +x create_ca_and_cert.sh
        source ./create_ca_and_cert.sh
        mkdir /etc/rabbitmq/ssl /usr/share/ssl/
        cp server/cert.pem /usr/share/ssl/
        cp server/key.pem /usr/share/ssl/
        cp ca/cacert.pem /usr/share/ssl/
        cp server/cert.pem /etc/rabbitmq/ssl/
        cp server/key.pem /etc/rabbitmq/ssl/
        cp ca/cacert.pem /etc/rabbitmq/ssl/
    else
        mkdir /etc/rabbitmq/ssl
        scp centos@$MASTERNODE:/usr/share/ssl/* /etc/rabbitmq/ssl/
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@$MASTERNODE
        rabbitmqctl start_app
fi
rabbitmqctl set_policy ha-all “” ‘{“ha-mode”:“all”,“ha-sync-mode”:“automatic”}’
sed -i  '/join_cluster.sh/d' /etc/rc.d/rc.local