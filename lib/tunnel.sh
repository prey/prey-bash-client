#!/bin/sh
# Auto SSH Tunnel script, by Tomas Pollak
# ./tunnel.sh [user] [pass] [host] [local_port] [remote_port]

# starting_port=$4
#get_port(){
#	search_ports=10
#	port=$starting_port

#	while [ -z "`telnet $3 $port < /dev/null 2>&1 | grep Connected`" ]; do
#		port=`expr $port + 1`
#		echo " -- Probing for connection on port $port..."
#		if [ $port -eq $(($starting_port+$search_ports)) ]; then
#			port=0
#			break
#		fi
#	done
# }

# trap cleanup_tunnel EXIT

cleanup_tunnel(){
	rm -Rf "$askfile" 2> /dev/null
}

cwd=`pwd`
askfile="$cwd/return"
export SSH_ASKPASS="$askfile"
export SSH_TTY=/dev/null
# export DISPLAY=none:0.0

cat > "$askfile" << END
#!/bin/sh
echo $2
END
chmod 700 "$askfile"

# eval `ssh-agent` >/dev/null
ssh-add < /dev/null

# echo " -- Connecting to $host_port..."
ssh -N -o 'ExitOnForwardFailure=yes' -R ${5}:localhost:${4} ${1}@${3} &
tunnel_pid=$!

sleep 5
if [ "`ps -p $tunnel_pid | grep $tunnel_pid`" ]; then
	echo "$tunnel_pid" > "prey-tunnel.pid"
fi
# cleanup_tunnel
