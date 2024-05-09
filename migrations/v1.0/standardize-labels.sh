#!/bin/bash

# We switched to the standard labels recommend in Helm's "Best Practices" doc.
# https://helm.sh/docs/chart_best_practices/labels/#standard-labels
#
# This script adds those labels to all the resources in an existing release,
# so that helm upgrade will not create duplicate resources. The new label
# selectors do not match the old labels, so this script adds the new labels
# to the old resources. Thus, the new selectors will update them.
#
# NOTE: This will orphan all Pods, but they will be adopted by the new Deployments.
# Specifically, we delete Deployment using propogationPolicy=Orphan,
# and then when Helm creates the Deployments again, the selector will match the
# current ReplicaSets (and their Pods) because we added the new labels.
# Finally, the standard k8s Deployment upgrade will gradually replace old Pods.

# These env vars need to be set to use this script:
#   RELEASE_NAME (same as .Release.Name)
#   NAMESPACE (same as .Release.Namespace)
#
# For example:
#   RELEASE_NAME=st2 NAMESPACE=st2 migrations/standardize-labels.sh

RELEASE_NAME=${RELEASE_NAME:-st2}
NAMESPACE=${NAMESPACE:-default}
CHART_NAME=${CHART_NAME:-stackstorm-ha} # see Chart.yaml

echo RELEASE_NAME=${RELEASE_NAME}
echo NAMESPACE=${NAMESPACE}
echo CHART_NAME=${CHART_NAME}

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

function kdelete_cascade_orphan() {
	kind=${1}
	app=${2}
	kubectl delete "${kind}" \
		-n "${NAMESPACE}" \
		-l "vendor=stackstorm" \
		-l "release=${RELEASE_NAME}" \
		-l "app=${app}" \
		--cascade=orphan
}

function k_get_app_names() {
	kind=${1}
	app=${2}
	kubectl get "${kind}" \
		-n "${NAMESPACE}" \
		-l "vendor=stackstorm" \
		-l "release=${RELEASE_NAME}" \
		-o json \
	| jq -r '.items[] | select(.metadata.name | test("'"${app}"'")).metadata.labels.app'
}

echo
echo "Adding label app.kubernetes.io/instance=${RELEASE_NAME} (which will replace release=${RELEASE_NAME}) ..."
echo

for kind in ConfigMap Secret Ingress Service ServiceAccount Deployment ReplicaSet Pod Job; do
	klabel_app_instance ${kind}
done

echo
echo "Adding label app.kubernetes.io/name=<app> (which will replace app=<app>) ..."
echo

klabel_app_name ConfigMap st2
klabel_app_name Secret st2
klabel_app_name Secret st2chatops
klabel_app_name ServiceAccount ${CHART_NAME}
klabel_app_name Ingress ingress

deployment_apps=(
	st2actionrunner
	st2api
	st2auth
	st2chatops
	st2client
	st2garbagecollector
	st2notifier
	st2rulesengine
	st2scheduler
	$(k_get_app_names Deployment st2sensorcontainer)
	st2stream
	st2timersengine
	st2web
	st2workflowengine
)
for app in "${deployment_apps[@]}"; do
	echo "ReplicaSet and Pods from Deployment app=${app} ..."
	klabel_app_name ReplicaSet ${app}
	klabel_app_name Pod ${app}
	echo "Deleting Deployment app=${app} (orphaning the ReplicaSets)..."
	kdelete_cascade_orphan Deployment ${app}
	# do not delete ReplicaSet or the Deployment will not adopt the pods
done

service_apps=(
	st2api
	st2auth
	st2chatops
	st2stream
	st2web
)
for app in "${service_apps[@]}"; do
	echo "Service app=${app} ..."
	klabel_app_name Service ${app}
done

job_apps=(
	st2
	st2-apply-rbac-definitions
	st2-register-content
	$(k_get_app_names Job extra-helm-hook)
)
for app in "${job_apps[@]}"; do
	echo "Job app=${app} ..."
	klabel_app_name Job ${app}
	klabel_app_name Pod ${app}
done

klabel_app_name ConfigMap st2tests
klabel_app_name Pod st2tests

echo
echo "ReplicaSets from Deployments have been orphaned, but new Deployments will adopt them."
echo "Make sure to run helm upgrade soon to create the new Deployments."
