#!/usr/bin/env bash
# Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

PROJECT_PATH="$1"
ECR_URI="$2"
CAPI_VERSION="$(cat ${PROJECT_PATH}/GIT_TAG)"

CAPI_CONTROLLER="${ECR_URI}/kubernetes-sigs/cluster-api/cluster-api-controller:latest"
KUBEADM_BOOTSTRAP="${ECR_URI}/kubernetes-sigs/cluster-api/kubeadm-bootstrap-controller:latest"
KUBEADM_CP="${ECR_URI}/kubernetes-sigs/cluster-api/kubeadm-control-plane-controller:latest"
CAPD_CONTROLLER="${ECR_URI}/kubernetes-sigs/cluster-api/capd-manager:latest"

RELEASE_MANIFEST="https://dev-release-assets.eks-anywhere.model-rocket.aws.dev/eks-a-release.yaml"
DEV_BUNDLE="$(curl -s https://dev-release-assets.eks-anywhere.model-rocket.aws.dev/eks-a-release.yaml | yq '.spec.releases[0].bundleManifestUrl')"
MANIFEST_PATH="${PROJECT_PATH}/_output/tar/manifests"
BUNDLE_NAME=${CAPI_VERSION}-bundle.yaml

mkdir -p temp
cd temp
curl -s ${DEV_BUNDLE} -o ${BUNDLE_NAME}
BUNDLE="$(realpath ${BUNDLE_NAME})"

uri=${CAPI_CONTROLLER} yq -i '.spec.versionsBundles[].clusterAPI.controller.uri = strenv(uri)' ${BUNDLE}
component=${MANIFEST_PATH}/cluster-api/${CAPI_VERSION}/core-components.yaml yq -i '.spec.versionsBundles[].clusterAPI.components.uri = strenv(component)' ${BUNDLE}
uri=${KUBEADM_BOOTSTRAP} yq -i '.spec.versionsBundles[].bootstrap.controller.uri = strenv(uri)' ${BUNDLE}
component=${MANIFEST_PATH}/bootstrap-kubeadm/${CAPI_VERSION}/bootstrap-components.yaml yq -i '.spec.versionsBundles[].bootstrap.components.uri = strenv(component)' ${BUNDLE}
uri=${KUBEADM_CP} yq -i '.spec.versionsBundles[].controlPlane.controller.uri = strenv(uri)' ${BUNDLE}
component=${MANIFEST_PATH}/control-plane-kubeadm/${CAPI_VERSION}/control-plane-components.yaml yq -i '.spec.versionsBundles[].controlPlane.components.uri = strenv(component)' ${BUNDLE}
uri=${CAPD_CONTROLLER} yq -i '.spec.versionsBundles[].docker.manager.uri = strenv(uri)' ${BUNDLE}
component=${MANIFEST_PATH}/infrastructure-docker/${CAPI_VERSION}/infrastructure-components-development.yaml yq -i '.spec.versionsBundles[].docker.components.uri = strenv(component)' ${BUNDLE}