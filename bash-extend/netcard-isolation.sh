SERVER=0
CLIENT=1

IF["${SERVER}"]="eth0"
IF["${CLIENT}"]="eth1"

# except "xxx.xxx.xxx.0/netmask"
IP_GROUP="192.168.50.0/24"
IP_FULL["${SERVER}"]=${IP_GROUP/.0/.1}
IP_FULL["${CLIENT}"]=${IP_GROUP/.0/.2}

IP["${SERVER}"]=${IP_FULL[${SERVER}]%%/*}
IP["${CLIENT}"]=${IP_FULL[${CLIENT}]%%/*}

# network namespace
NS["${SERVER}"]="ns_server"
NS["${CLIENT}"]="ns_client"

ns_if_up()
{
	# $1 := ${SERVER} | ${CLIENT}
	echo init ${NS[$1]} 
	echo ip netns add ${NS["$1"]}
	echo ip link set ${IF[$1]} netns ${NS[$1]}
	echo ip netns exec ${NS[$1]} ip addr add dev ${IF[$1]} ${IP_FULL[$1]}
	echo ip netns exec ${NS[$1]} ip link set dev ${IF[$1]} up
}

ns_if_down()
{
	echo destroy ${NS[$1]} 
	echo ip netns delete ${NS["$1"]}
}

help()
{
	echo "$0 init | destroy | info | example"
}

info()
{
	echo '-------------------------'
	echo "list network namespacke:"
	ip netns list
}

example()
{
	echo '-------------------------'
	echo "iperf example"
	echo "sudo ip netns exec ${NS[${SERVER}]} iperf -s -B ${IP[${SERVER}]}"
	echo "sudo ip netns exec ${NS[${CLIENT}]} iperf -c ${IP[${SERVER}]} -B ${IP[${CLIENT}]}"
}

case $@ in
init)
	ns_if_up "${SERVER}"
	ns_if_up "${CLIENT}"
	;;
destroy)
	ns_if_down "${SERVER}"
	ns_if_down "${CLIENT}"
	;;
info) info ;;
example) example ;;
*) help ;;
esac
