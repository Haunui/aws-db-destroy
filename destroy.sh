#!/usr/bin/bash

shutdown_instance() {
	STATE=$1
	INSTANCE_ID=$2

	while [[ $STATE != terminated ]]; do
		echo "Waiting for '$INSTANCE_ID' to shutdown.. (status : $STATE)"
		STATE=$(aws ec2 terminate-instances --instance-ids $INSTANCE_ID | jq ".TerminatingInstances[] | select(.InstanceId==\"$INSTANCE_ID\") | .CurrentState.Name" | sed 's/"//g')
		sleep 5
	done

	echo "Waiting for '$INSTANCE_ID' to shutdown.. (status : $STATE)"
}

while IFS= read -r line; do
	INSTANCE_ID=$(echo "$line" | jq '.InstanceId' | sed 's/"//g')
	STATE=$(echo "$line" | jq '.State.Name' | sed 's/"//g')

	if [[ $STATE != terminated ]]; then
		f=1
		for i in {0..20}; do
			if [ -z "${pids[${i}]}" ]; then
				shutdown_instance "$STATE" "$INSTANCE_ID" &
				pids[${i}]=$!
				break
			fi
		done
		
	fi 
done < <(aws ec2 describe-instances --filters Name=tag:Name,Values=HSAINT-instance --query 'Reservations[*]' | jq -c '.[].Instances[]')

sleep 3

for pid in ${pids[@]}; do
	wait $pid
done

if [ -z "$f" ]; then
	echo "Nothing to do."
else
	echo "Cleanup done."
fi
