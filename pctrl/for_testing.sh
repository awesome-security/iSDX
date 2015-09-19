#!/bin/sh

server="server2"
EXPERIMENT_NAME='change_frac'
NUMBER_OF_PARTICIPANTS=1
INSTALL_ROOT='/home/glex/sdx-parallel'
EXAMPLE_NAME='test-largeIX'
UPDATE_FILE='updates.txt'
ITERATIONS=1
FRAC=(0.2)
RATE=5
MODE=0

cd $INSTALL_ROOT/examples/$EXAMPLE_NAME/ribs ; rm -rf ribs_AS*

cd $INSTALL_ROOT/examples/$EXAMPLE_NAME; python generate_configs.py $server; cp $INSTALL_ROOT/examples/$EXAMPLE_NAME/asn_2_* $INSTALL_ROOT/pctrl

cd $INSTALL_ROOT/examples/$EXAMPLE_NAME/ribs; python duplicate_ribs.py

for iter in `seq 1 $ITERATIONS`
do
	echo "#### Running for Iteration $iter ####"
	for fraction in "${FRAC[@]}"
	do

		# Generate Policies & Copy asn json files
		echo "Generating policies for $fraction"
		cd $INSTALL_ROOT/examples/$EXAMPLE_NAME; python generate_policies.py $fraction
	
		# Clean DB & Initialize the rib
		echo "Cleaning MongoDB & Initializing Participant Rib"
		cd $INSTALL_ROOT/pctrl ; . clean.sh

		# Initialize Ribs
		echo "Initialize Ribs for $server"
		cd $INSTALL_ROOT/pctrl ; python initialize_ribs.py $server $EXAMPLE_NAME

		if [ $server == "server1" ]; then
			# Start the reflog
			echo "Starting Reflog..."
			#`cd $INSTALL_ROOT/flanc ; nohup ./reflog.py 0.0.0.0 5555 sdx logger.txt > /dev/null 2>&1 &`
		fi

		if [ $server == "server2" ]; then
			# Start Route Server
			echo "Starting RouteServer..."
			#`cd $INSTALL_ROOT/xrs ; nohup python route_server.py $EXAMPLE_NAME > /dev/null 2>&1 &`
		fi
	
		# Start Participant controller
		OUTPUT_FILE_NAME=$EXPERIMENT_NAME"_FRAC"$fraction"_ITER"$iter
		#cd $INSTALL_ROOT/pctrl ; python run_participants.py $INSTALL_ROOT $server $EXAMPLE_NAME $OUTPUT_FILE_NAME > /dev/null 2>&1 &

		if [ $server == "server3" ]; then
			#Starting XBGP	
			echo "Starting XBGP..."
			#`cd $INSTALL_ROOT/xbgp ; nohup ./xbgp.py localhost 6000 xrs $UPDATE_FILE $RATE $MODE > /dev/null 2>&1 &` 
		fi
		while [ `ps axf | grep xbgp | grep -v grep | wc -l` -ne 0 ] 
		do 
			echo "running"
			sleep 1m
		done
		#sleep 5m
		#`ps axf | grep participant_controller | grep -v grep | awk '{print "kill -SIGINT " $1}' | { while IFS= read -r cmd; do  $cmd; done }`
		#sleep 30
		echo "completed for $fraction"
	done
done