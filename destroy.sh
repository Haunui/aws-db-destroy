#!/usr/bin/bash

SSH_OPTS="-o StrictHostKeyChecking=no"

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

if ! ssh $SSH_OPTS $BKP_SSH_LOGIN "cat $BKP_PATH/instance_ip" < /dev/null > instance_ip; then
  echo "No instance found"
  echo "Nothing to do."
  exit 0
fi

IP=$(cat instance_ip)

INSTANCE_DATA=$(aws ec2 describe-instances --filters Name=tag:Name,Values=HSAINT-instance --query 'Reservations[*]' | jq -c ".[].Instances[] | select(.PublicIpAddress==\"$IP\")")

if [ -z "$INSTANCE_DATA" ]; then
  echo "Instance (IP: $IP) not found."
  ssh $SSH_OPTS $BKP_SSH_LOGIN "rm -f $BKP_PATH/instance_ip" < /dev/null
  exit 0
fi

INSTANCE_ID=$(echo "$INSTANCE_DATA" | jq '.InstanceId' | sed 's/"//g')
STATE=$(echo "$INSTANCE_DATA" | jq '.State.Name' | sed 's/"//g')
	
if [[ $STATE != terminated ]]; then
  f=1
  shutdown_instance "$STATE" "$INSTANCE_ID"
fi

if [ -z "$f" ]; then
	echo "Nothing to do."
else
	echo "Cleanup done."
fi
