#!/bin/bash

COMPONENT=$1

## -z validates the variable empty , true if it is empty.
if [ -z "${COMPONENT}" ]; then
  echo "Component Input is Needed"
  exit 1
fi

LID=lt-0b72827b0db69bd4
LVER=1

## Validate If Instance is already there
DNS_UPDATE() {
  PRIVATEIP=$(aws --region us-east-1 ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}"  | jq .Reservations[].Instances[].PrivateIpAddress | xargs -n1)
  sed -e "s/COMPONENT/${COMPONENT}/" -e "s/IPADDRESS/${PRIVATEIP}/" record.json >/tmp/record.json
  aws route53 change-resource-record-sets --hosted-zone-id Z0724247R4KE3AIA5B4P --change-batch file:///tmp/record.json | jq
}

INSTANCE_CREATE(){
  INSTANCE_STATE=$(aws --region us-east-1 ec2 describe-instances --filters "Name=tag:Name,Values=${COMPONENT}"  | jq .Reservations[].Instances[].State.Name | xargs -n1)
  if [ "${INSTANCE_STATE}" = "running" ]; then
    echo "${COMPONENT} Instance already exists!!"
    DNS_UPDATE
    return 0
  fi

  if [ "${INSTANCE_STATE}" = "stopped" ]; then
    echo "${COMPONENT} Instance already exists!!"
    return 0
  fi

echo -n Instance ${COMPONENT} created - IPADDRESS is
  aws --region us-east-1 ec2 run-instances --launch-template LaunchTemplateId=${LID},Version=${LVER}  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}}]" | jq | grep PrivateIpAddress | xargs -n1
  sleep 10
  DNS_UPDATE
}
if [ "${1}" == "all" ]; then
  for components in frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment ; do
  COMPONENT=$components
  INSTANCE_CREATE
    done
    else
  INSTANCE_CREATE
  COMPONENT=$1
fi







