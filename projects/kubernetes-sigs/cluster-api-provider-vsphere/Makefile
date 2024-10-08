BASE_DIRECTORY:=$(abspath ../../../)
GIT_TAG=$(shell cat GIT_TAG)
GOLANG_VERSION=$(shell cat GOLANG_VERSION)
REPO=cluster-api-provider-vsphere
REPO_OWNER=kubernetes-sigs

BASE_IMAGE_NAME?=eks-distro-minimal-base-nonroot

BINARY_TARGET_FILES=manager
EXTRA_GO_LDFLAGS=$(shell $(BUILD_LIB)/version.sh $(REPO) sigs.k8s.io/cluster-api-provider-vsphere/pkg/version)

IMAGE_COMPONENT=kubernetes-sigs/cluster-api-provider-vsphere/release/manager

HAS_S3_ARTIFACTS=true

FIX_LICENSES_VM_OPERATOR_TARGET=$(REPO)/vendor/github.com/vmware-tanzu/vm-operator/api/v1alpha1/LICENSE.txt $(REPO)/vendor/github.com/vmware-tanzu/vm-operator/external/tanzu-topology/api/v1alpha1/LICENSE.txt

include $(BASE_DIRECTORY)/Common.mk


s3-artifacts: create-manifests

$(GATHER_LICENSES_TARGETS): | $(FIX_LICENSES_VM_OPERATOR_TARGET)

.PHONY: create-manifests
create-manifests: tarballs | ensure-yq $$(ENABLE_DOCKER)
	@build/create_manifests.sh $(REPO) $(OUTPUT_DIR) $(ARTIFACTS_PATH) $(GIT_TAG) $(IMAGE_REPO) $(IMAGE_TAG) $(GOLANG_VERSION)

$(FIX_LICENSES_VM_OPERATOR_TARGET): | $(GO_MOD_DOWNLOAD_TARGETS)
# The vmware-tanzu/vm-operator dependency github repo has a license however, ncp is a subfolder
# without its own license. Hence we need to manually download parent license from Github
# and place it in the respective folder under vendor directory so that it is available for 
# go-licenses to pick up	
	for package in ncp ; do \
		wget --retry-connrefused -q https://raw.githubusercontent.com/vmware-tanzu/vm-operator/main/LICENSE.txt -O \
			$(REPO)/vendor/github.com/vmware-tanzu/vm-operator/external/$$package/api/v1alpha1/LICENSE.txt; \
	done;
	wget --retry-connrefused -q https://raw.githubusercontent.com/vmware-tanzu/vm-operator/main/LICENSE.txt -O \
			$(REPO)/vendor/github.com/vmware-tanzu/vm-operator/api/v1alpha2/LICENSE.txt


########### DO NOT EDIT #############################
# To update call: make add-generated-help-block
# This is added to help document dynamic targets and support shell autocompletion
# Run make help for a formatted help block with all targets
include Help.mk
########### END GENERATED ###########################
