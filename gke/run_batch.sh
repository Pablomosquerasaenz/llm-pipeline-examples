#!/bin/bash -e
# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
EXIT_CODE = 0

_invoke_cluster_tool () {
  echo "Invoking cluster tool"
  echo PROJECT_ID $PROJECT_ID
  echo NAME_PREFIX $NAME_PREFIX
  echo ZONE $ZONE
  echo INSTANCE_COUNT $INSTANCE_COUNT
  echo GPU_COUNT $GPU_COUNT
  echo VM_TYPE $VM_TYPE
  echo ACCELERATOR_TYPE $ACCELERATOR_TYPE
  echo IMAGE_FAMILY_NAME $IMAGE_FAMILY_NAME
  echo IMAGE_NAME $IMAGE_NAME
  echo DISK_SIZE_GB $DISK_SIZE_GB
  echo DISK_TYPE $DISK_TYPE
  echo TERRAFORM_GCS_PATH $TERRAFORM_GCS_PATH
  echo VM_LOCALFILE_DEST_PATH $VM_LOCALFILE_DEST_PATH
  echo METADATA $METADATA
  echo LABELS $LABELS
  echo STARTUP_COMMAND $STARTUP_COMMAND
  echo ORCHESTRATOR_TYPE $ORCHESTRATOR_TYPE
  echo GCS_MOUNT_LIST $GCS_MOUNT_LIST
  echo NFS_FILESHARE_LIST $NFS_FILESHARE_LIST
  echo SHOW_PROXY_URL $SHOW_PROXY_URL
  echo MINIMIZE_TERRAFORM_LOGGING $MINIMIZE_TERRAFORM_LOGGING
  echo NETWORK_CONFIG $NETWORK_CONFIG
  echo ACTION $ACTION
  echo GKE_NODE_POOL_COUNT $GKE_NODE_POOL_COUNT
  echo GKE_NODE_COUNT_PER_NODE_POOL $GKE_NODE_COUNT_PER_NODE_POOL
  /usr/entrypoint.sh
}

if [[ -z $CLUSTER_ID ]]; then

  export SERVICE_ACCOUNT=$(gcloud config get account)
  export OS_LOGIN_USER=$(gcloud iam service-accounts describe ${SERVICE_ACCOUNT} | grep uniqueId | sed -e "s/.* '\(.*\)'/sa_\1/")

  echo User is ${OS_LOGIN_USER}

  export ACTION=CREATE
  export METADATA="{install-unattended-upgrades=\"false\",enable-oslogin=\"TRUE\",jupyter-user=\"${OS_LOGIN_USER}\",install-nvidia-driver=\"True\"}"
  export SHOW_PROXY_URL=no
  export LABELS="{gcpllm=\"$CLUSTER_PREFIX\"}"
  export MINIMIZE_TERRAFORM_LOGGING=true
  _invoke_cluster_tool

  echo "Provisioning cluster..."
  export CLUSTER_ID=${NAME_PREFIX}-gke
  
  gcloud container clusters get-credentials $CLUSTER_ID --region $REGION --project $PROJECT_ID
  
  # Apply Nvidia daemonset
  kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml

  # TODO: need to create Kubernetes Service Account that is linked to Workload Identity
fi

# Get kubeconfig for cluster
REGION=${ZONE%-*}
gcloud container clusters get-credentials $CLUSTER_ID --region $REGION --project $PROJECT_ID

# Run convert image on cluster
export CONVERT_JOB_ID=convert-$RANDOM
envsubst < specs/convert.yml | kubectl apply -f -
kubectl wait --for=condition=complete --timeout=10m job/$CONVERT_JOB_ID

# Run deploy-gke image on cluster
envsubst < specs/inference.yml | kubectl apply -f -

exit $EXIT_CODE
