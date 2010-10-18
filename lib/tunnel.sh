#!/bin/sh
# Auto SSH Reverse Tunnel script, by Tomas Pollak
# ./tunnel.sh [host] [local_port] [remote_port] [user] [pass]

# trap cleanup_tunnel EXIT

cwd=`pwd`

cleanup_tunnel(){
	rm -Rf "$askfile" 2> /dev/null
}

create_askfile(){

	askfile="$cwd/ssh_askpass"

cat > "$askfile" << END
#!/bin/sh
echo $1
END

	chmod 700 "$askfile"
}

if [ -n "$5" ]; then # using password-based authentication

	create_askfile "$5"
	export SSH_ASKPASS="$askfile"
	export SSH_TTY=/dev/null
	# export DISPLAY=none:0.0
	# eval `ssh-agent` >/dev/null
	ssh-add < /dev/null

fi

# echo " -- Connecting to $host_port..."
ssh -N -o 'ExitOnForwardFailure=yes' -R ${3}:localhost:${2} ${4}@${1} &
tunnel_pid=$!

sleep 3
if [ "`ps -p $tunnel_pid | grep $tunnel_pid`" ]; then
	echo "$tunnel_pid" > "prey-tunnel.pid"
fi

cleanup_tunnel
