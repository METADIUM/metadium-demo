#!/bin/bash

[ "$DIR" = "" ] && DIR=/opt
NODE=$(hostname -s)
NODE_DIR=${DIR}/${NODE}
GMET=${NODE_DIR}/bin/gmet
GMET_SH=${NODE_DIR}/bin/gmet.sh
NODES=

IS_LEADER=0

function _install ()
{
    [ -f $NODE_DIR/bin/gmet ] && return 0
    mkdir -p $NODE_DIR || return 1
    cp -r /usr/local/metadium/bin /usr/local/metadium/conf /usr/local/metadium/keystore $NODE_DIR/ || return 1
    chmod 0700 $NODE_DIR/keystore || return 1
    return 0;
}

function do_admin ()
{
    TOADDR=
    while true; do
	TOADDR=$($GMET attach ipc:$NODE_DIR/geth.ipc -exec "admin.metadiumInfo.to" 2> /dev/null | grep "^\"0x")
	[ "$TOADDR" = "" ] || break
	sleep 1
    done

    [ "$TOADDR" = \"0x0000000000000000000000000000000000000000\" ] || return 0

    echo 'personal.unlockAccount(eth.accounts[0], "demo", 3600);
loadScript("MetadiumAdmin.js");
Admin_new();' | $GMET attach ipc:$NODE_DIR/geth.ipc > /dev/null 2>&1

    TOADDR=
    while true; do
	TOADDR=$($GMET attach ipc:$NODE_DIR/geth.ipc -exec "admin.metadiumInfo.to" 2> /dev/null | grep "^\"0x")
	if [ "$TOADDR" = "" -o "$TOADDR" = \"0x0000000000000000000000000000000000000000\" ]; then
	    sleep 1
	else
	    return 0
	fi
    done
}

function start ()
{
    _install || exit $?;

    if [ ! -f $NODE_DIR/geth/nodekey ]; then
	mkdir -p $NODE_DIR/geth || exit $?
	$GMET metadium new-nodekey --out $NODE_DIR/geth/nodekey
    fi

    if [ ! -d $NODE_DIR/geth/chaindata ]; then
	# need to initialize

	# waiting for config.json to be created by the leader
	while [ ! -f $NODE_DIR/config.json ]; do
	    sleep 1
	done

	$GMET_SH init $NODE $NODE_DIR/config.json 10009

	/usr/local/metadium/bin/solc.sh -g 0x10000000 -p 1 $NODE_DIR/MetadiumAdmin.sol $NODE_DIR/MetadiumAdmin.js
    fi
    
    cd /opt/$NODE;
    if [ "$IS_LEADER" = "1" ]; then
	(do_admin) &
    fi

    echo "About to $GMET_SH start $NODE"
    exec $GMET_SH start-inner $NODE
}

function start_leader ()
{
    IS_LEADER=1

    _install || exit $?;

    COUNT=$(echo $NODES | wc -w)
    if [ "$COUNT" = "" ]; then
	echo "NODES should not be empty"
	return 1
    fi
    if [ "$COUNT" -le 0 ]; then
	echo "NODES should not be empty"
	return 1
    fi

    # take care of dags
    if [ ! -d $NODE_DIR/.ethash ]; then
        mkdir -p $NODE_DIR/.ethash
        ${GMET} makedag 0 $NODE_DIR/.ethash
        for i in $NODES; do
            [ $i = $NODE ] && continue
            mkdir -p $DIR/$i/.ethash
            cp $NODE_DIR/.ethash/* $DIR/$i/.ethash/;
        done
    fi

    if [ ! -f $NODE_DIR/geth/nodekey ]; then
	mkdir -p $NODE_DIR/geth || exit $?
	$GMET metadium new-nodekey --out $NODE_DIR/geth/nodekey
    fi

    if [ ! -f $NODE_DIR/config.json ]; then

	while true; do
	    FOUND=0
	    NODE_DATA=
	    for i in $NODES; do
		if [ ! -f $DIR/$i/geth/nodekey ]; then
		    continue
		else
		    i_IP=$(getent hosts $i | awk '{print $1}')
		    i_ID=$(/usr/local/metadium/bin/gmet metadium nodeid $DIR/$i/geth/nodekey)
		    [ ! $FOUND = 0 ] && NODE_DATA="${NODE_DATA},"
		    NODE_DATA="${NODE_DATA}
    {
      \"name\": \"$i\",
      \"ip\": \"$i_IP\",
      \"port\": 10009,
      \"id\": \"0x$i_ID\"
    }"
		    FOUND=$(($FOUND + 1))
		fi
	    done
	    [ "$FOUND" = "$COUNT" ] && break
	    sleep 1;
	done

	FIRST=
	FN=$NODE_DIR/config.json.junk
	echo "{
  \"members\": [" > $FN
	for i in $(ls -1 $NODE_DIR/keystore/); do
	    ADDR=$(sed -e 's/^{"address":"\([a-zA-Z0-9]\+\).*$/\1/' < $NODE_DIR/keystore/$i)
	    [ "$FIRST" = "" ] || echo "," >> $FN
	    echo -n "    {
      \"addr\": \"0x${ADDR}\",
      \"balance\": 10000000000000000,
      \"stake\": 250000
    }" >> $FN
	    FIRST=nah
	done
	echo "
  ]," >> $FN
	echo "  \"nodes\": [$NODE_DATA
  ]
}" >> $FN
	
	mv -f $NODE_DIR/config.json.junk $NODE_DIR/config.json
	for i in $NODES; do
	    [ $i = $NODE ] && continue
	    cp $NODE_DIR/config.json ${DIR}/$i/
	done
    fi

    start
}

function usage ()
{
    echo "Usage: `basename $0` [start | start-leader <node>+]"
}

case "$1" in
"start")
    start
    ;;
"start-leader")
    shift;
    NODES="$*"
    start_leader
    ;;
*)
    usage;
    ;;
esac

# EOF
