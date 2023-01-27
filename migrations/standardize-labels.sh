#!/bin/bash

# We switched to the standard labels recommend in Helm's "Best Practices" doc.                                  
# https://helm.sh/docs/chart_best_practices/labels/#standard-labels
#
# This script adds those labels to all the resources in an existing release,
# so that helm upgrade will not create duplicate resources. The new label
# selectors do not match the old labels, so this script adds the new labels
# to the old resources. Thus, the new selectors will update them.

# These env vars need to be set to use this script:
#   RELEASE_NAME (same as .Release.Name)
#   NAMESPACE (same as .Release.Namespace)
#
# For example:
#   RELEASE_NAME=st2 NAMESPACE=st2 migrations/standardize-labels.sh

RELEASE_NAME=${RELEASE_NAME:-st2}
NAMESPACE=${NAMESPACE:-default}
CHART_NAME=${CHART_NAME:-stackstorm-ha} # see Chart.yaml


function klabel_app_instance() {
	kind=${1}
	kubectl label "${kind}" \
		-n "${NAMESPACE}" \
		-l "vendor=stackstorm" \
		-l "release=${RELEASE_NAME}" \
		"app.kubernetes.io/instance=${RELEASE_NAME}"
}

function klabel_app_name() {
	kind=${1}
	app=${2}
	kubectl label "${kind}" \
		-n "${NAMESPACE}" \
		-l "vendor=stackstorm" \
		-l "release=${RELEASE_NAME}" \
		-l "app=${app}" \
		"app.kubernetes.io/name=${app}"
}

for kind in ConfigMap Secret Ingress Service ServiceAccount Deployment ReplicaSet Pod Job; do
	klabel_app_instance ${kind}
done

klabel_app_name ConfigMap st2
klabel_app_name Secret st2
klabel_app_name Secret st2chatops
klabel_app_name Secret ${CHART_NAME} # for ServiceAccount
klabel_app_name ServiceAccount ${CHART_NAME}
klabel_app_name Ingress ingress

for app in st2actionrunner st2api st2auth st2chatops st2client st2garbagecollector st2notifier st2rulesengine st2scheduler st2stream st2timersengine st2web st2workflowengine; do
	klabel_app_name Deployment ${app}
	klabel_app_name ReplicaSet ${app}
	klabel_app_name Pod ${app}
done

for app in st2api st2auth st2chatops st2stream st2web; do
	klabel_app_name Service ${app}
done

for app in st2 st2-apply-rbac-definitions st2-register-content; do
	klabel_app_name Job ${app}
	klabel_app_name Pod ${app}
done
