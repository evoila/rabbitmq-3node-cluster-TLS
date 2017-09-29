export MASTERNODE=rmq-1
if [ "$MASTERNODE" != "$HOSTNAME" ]
    then
        mkdir /etc/rabbitmq/ssl
        scp $MASTERNODE:/usr/share/ssl/* /etc/rabbitmq/ssl/
        chown rabbitmq:rabbitmq /etc/rabbitmq/* -R
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@$MASTERNODE
        rabbitmqctl start_app
fi
rabbitmqctl set_policy ha-all “” ‘{“ha-mode”:“all”,“ha-sync-mode”:“automatic”}’
sed -i  '/join_cluster.sh/d' /etc/rc.d/rc.local