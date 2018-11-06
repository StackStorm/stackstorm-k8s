#!/bin/bash

# Set the DNS record prefix & the Service name and then retrieve the ELB URL
export DNS_RECORD_PREFIX="st2web"
export DOMAIN_NAME="stackstorm.net"
export SERVICE_NAME="st2cicd-st2web-enterprise"
export ST2WEB_APP_ELB=$(kubectl get svc/${SERVICE_NAME} \
       --template="{{range .status.loadBalancer.ingress}} {{.hostname}} {{end}}")
export DOMAIN_NAME_ZONE_ID=$(aws route53 list-hosted-zones \
       | jq -r '.HostedZones[] | select(.Name=="'${DOMAIN_NAME}'.") | .Id' \
       | sed 's/\/hostedzone\///')

# Add to JSON file
sed -i -e 's|"Name": ".*|"Name": "'"${DNS_RECORD_PREFIX}.${DOMAIN_NAME}"'",|g' dns.json
sed -i -e 's|"Value": ".*|"Value": "'"${ST2WEB_APP_ELB}"'"|g' dns.json

echo DOMAIN_NAME_ZONE_ID=${DOMAIN_NAME_ZONE_ID}

# Create DNS record
aws route53 change-resource-record-sets \
    --hosted-zone-id ${DOMAIN_NAME_ZONE_ID} \
    --change-batch file://dns.json
