#! /bin/sh
export $MASTERNODE=rmq-1
export $RMQ_ADMIN=admin
export $RMQ_PASSWORD=password

yum install wget
yum install epel-release
wget https://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
yum install erlang-19.3-1.el7.centos
yum install socat
wget https://bintray.com/rabbitmq/rabbitmq-server-rpm/download_file?file_path=rabbitmq-server-3.6.9-1.el6.noarch.rpm
rpm -ihv rabbitmq-server-3.6.9-1.el6.noarch.rpm
systemctl stop firewalld
systemctl disable firewalld
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
./create_ca_and_cert.sh
rabbitmqctl add_user $RMQ_ADMIN &RMQ_PASSWORD
rabbitmqctl set_user_tags $RMQ_ADMIN administrator
rabbitmqctl set_permissions -p / $RMQ_ADMIN ".*" ".*" ".*"
echo "[{rabbit, [
     {tcp_listeners, [{"127.0.0.1", 5671}, # Lokaler Listener für rabbitmqctl Zugriff auf Nodes
                     {"::1",   	5671}]},
     {ssl_listeners, [{"0.0.0.0", 5672}, # TLS Listener für AMQP Verbindungen
                     {"::1",   	5672}]},
 
     {ssl_options, [{cacertfile,"/etc/rabbitmq/ssl/cacert.pem"}, # CA Zertifikat
                    {certfile,"/etc/rabbitmq/ssl/cert.pem"}, # Server Zertifikat
                    {keyfile,"/etc/rabbitmq/ssl/key.pem"}, # Server Key
                    {verify,verify_peer},
                    {fail_if_no_peer_cert,false}]}
   ]},
 
  {rabbitmq_management,
               [{listener, [{port, 	15672},
               {ssl,  	true}, # https für WebUi
               {ssl_opts, [{cacertfile, "/etc/rabbitmq/ssl/cacert.pem"}, # CA Zertifikat
                       	{certfile,   "/etc/rabbitmq/ssl/cert.pem"}, # Server Zertifikat
                       	{keyfile,	"/etc/rabbitmq/ssl/key.pem"}]} # Server Key
          	]}
  ]}
]." >> /etc/rabbitmq/rabbitmq.conf
systemctl restart rabbitmq-server
export ERLSSLLIB=`erl -eval 'io:format("~p", [code:lib_dir(ssl, ebin)]),halt().' -noshell` 
cat "RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS="-pa $ERLSSLLIB -proto_dist inet_tls -ssl_dist_opt server_certfile /etc/rabbitmq/ssl/inter-node.pem -ssl_dist_opt server_secure_renegotiate true client_secure_renegotiate true"
RABBITMQ_CTL_ERL_ARGS="-pa $ERLSSLLIB -proto_dist inet_tls -ssl_dist_opt server_certfile /etc/rabbitmq/ssl/inter-node.pem -ssl_dist_opt server_secure_renegotiate true client_secure_renegotiate true"" >> /etc/rabbitmq/rabbitmq-env.conf
if [$MASTERNODE = $HOSTNAME]
    then
        
    else
        rabbitmqctl stop_app
        rabbitmqctl join_cluster rabbit@$MASTERNODE
fi
rabbitmqctl set_policy ha-all “” ‘{“ha-mode”:“all”,“ha-sync-mode”:“automatic”}’
systemctl restart rabbitmq-server