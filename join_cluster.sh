export MASTERNODE=rmq-1
if [ "$MASTERNODE" == "$HOSTNAME" ]
    then
        
    else
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@$MASTERNODE
fi