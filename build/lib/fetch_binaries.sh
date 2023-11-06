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

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_ROOT}/common.sh"

BINARY_DEPS_DIR="$1" 
DEP="$2"
ARTIFACTS_BUCKET="$3"
LATEST_TAG="$4"
RELEASE_BRANCH="${5-$(build::eksd_releases::get_release_branch)}"

DEP=${DEP#"$BINARY_DEPS_DIR"}
OS_ARCH="$(cut -d '/' -f1 <<< ${DEP})"
PRODUCT=$(cut -d '/' -f2 <<< ${DEP})
REPO_OWNER=$(cut -d '/' -f3 <<< ${DEP})
REPO=$(cut -d '/' -f4 <<< ${DEP})

RELEASE_BRANCH_OVERRIDE=$(cut -d '/' -f5 <<< ${DEP})
RELEASE_BRANCH=${RELEASE_BRANCH_OVERRIDE:-$RELEASE_BRANCH}

ARCH="$(cut -d '-' -f2 <<< ${OS_ARCH})"
CODEBUILD_CI="${CODEBUILD_CI:-false}"

OUTPUT_DIR_FILE=$BINARY_DEPS_DIR/linux-$ARCH/$PRODUCT/$REPO_OWNER/$REPO

if [[ -n "$RELEASE_BRANCH_OVERRIDE" ]]; then
    OUTPUT_DIR_FILE+=/$RELEASE_BRANCH_OVERRIDE
fi

if [[ $PRODUCT = 'eksd' ]]; then
    if [[ $REPO_OWNER = 'kubernetes' ]]; then
        TARBALL="kubernetes-$REPO-linux-$ARCH.tar.gz"
        URL=$(build::common::echo_and_run build::eksd_releases::get_eksd_kubernetes_asset_url $TARBALL $RELEASE_BRANCH $ARCH)
        # these tarballs will extra with the kubernetes/{client,server} folders
        OUTPUT_DIR_FILE=$BINARY_DEPS_DIR/linux-$ARCH/$PRODUCT
    else
        URL=$(build::common::echo_and_run build::eksd_releases::get_eksd_component_url $REPO_OWNER $RELEASE_BRANCH $ARCH)
    fi
    SHA_URL="$URL.sha256"
else
    URL="$(build::common::echo_and_run build::common::get_latest_eksa_asset_url $ARTIFACTS_BUCKET $REPO_OWNER/$REPO $ARCH $LATEST_TAG $RELEASE_BRANCH)"
    SHA_URL="$(build::common::echo_and_run build::common::get_latest_eksa_asset_url_sha256 $ARTIFACTS_BUCKET $REPO_OWNER/$REPO $ARCH $LATEST_TAG $RELEASE_BRANCH)"
fi

if [ "$CODEBUILD_CI" = "true" ]; then
    build::common::echo_and_run build::common::wait_for_tarball $URL
fi

DOWNLOAD_DIR=$(mktemp -d)
trap "rm -rf $DOWNLOAD_DIR" EXIT

FILENAME_AND_POSSIBLE_QUERY=${URL##*/}

build::common::echo_and_run wget -q --retry-connrefused "$URL" -O $DOWNLOAD_DIR/${FILENAME_AND_POSSIBLE_QUERY%%[?#]*}
build::common::echo_and_run wget -q --retry-connrefused "$SHA_URL" -O $DOWNLOAD_DIR/${FILENAME_AND_POSSIBLE_QUERY%%[?#]*}.sha256
(cd $DOWNLOAD_DIR && sha256sum -c *.sha256)

if [[ $REPO == *.tar.gz ]]; then
    mkdir -p $(dirname $OUTPUT_DIR_FILE)
else
    mkdir -p $OUTPUT_DIR_FILE
fi

if [[ $REPO == *.tar.gz ]]; then
    build::common::echo_and_run mv $DOWNLOAD_DIR/*.tar.gz $OUTPUT_DIR_FILE
else
    build::common::echo_and_run tar xzf $DOWNLOAD_DIR/*.tar.gz -C $OUTPUT_DIR_FILE
fi
