#!/usr/bin/env bash

set -euxo pipefail

# Prerequisites:
# - awk
# - jq
# - sed
# - skopeo
# - yq

# --- ARGO-CD variables ---
# Define the version and tag for the Argo CD image.
GITOPS_VERSION="1.16.1-1"
GITOPS_TAG="v"${GITOPS_VERSION}

# --- REDIS variables ---
# Define the tag for the Redis image.
REDIS_TAG="9.6-1753161831"

# --- ARGOCD build steps (brew removed) ---

# Directly define the Argo CD container image URL.
ARGO_CD_IMAGE_URL="registry.redhat.io/openshift-gitops-1/argocd-rhel9:${GITOPS_TAG}"
# Use the static version for the release info file.
ARGO_CD_IMAGE_TAG="${GITOPS_VERSION}"

# Get the SHA id for the respective processor architectures using skopeo.
ARGO_CD_IMAGE_SHA_X86=$(skopeo inspect docker://${ARGO_CD_IMAGE_URL} --raw | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
ARGO_CD_IMAGE_SHA_ARM=$(skopeo inspect docker://${ARGO_CD_IMAGE_URL} --raw | jq -r '.manifests[] | select(.platform.architecture=="arm64") | .digest')

# Update the vars to be replaced in the spec template file.
sed -i "s/REPLACE_ARGO_CD_CONTAINER_SHA_X86/${ARGO_CD_IMAGE_SHA_X86}/g" microshift-gitops.spec.in
sed -i "s/REPLACE_ARGO_CD_CONTAINER_SHA_ARM/${ARGO_CD_IMAGE_SHA_ARM}/g" microshift-gitops.spec.in
sed -i "s/REPLACE_ARGO_CD_VERSION/${ARGO_CD_IMAGE_TAG}/g" microshift-gitops.spec.in

# Update the final spec file.
sed -i "s/REPLACE_ARGO_CD_CONTAINER_SHA_X86/${ARGO_CD_IMAGE_SHA_X86}/g" microshift-gitops.spec
sed -i "s/REPLACE_ARGO_CD_CONTAINER_SHA_ARM/${ARGO_CD_IMAGE_SHA_ARM}/g" microshift-gitops.spec
sed -i "s/REPLACE_ARGO_CD_VERSION/${ARGO_CD_IMAGE_TAG}/g" microshift-gitops.spec

# --- REDIS build steps (brew removed) ---

# Directly define the Redis container image URL.
REDIS_IMAGE_URL="registry.redhat.io/rhel9/redis-6:${REDIS_TAG}"

# Get the SHA id for the respective processor architectures using skopeo.
REDIS_IMAGE_SHA_X86=$(skopeo inspect docker://${REDIS_IMAGE_URL} --raw | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
REDIS_IMAGE_SHA_ARM=$(skopeo inspect docker://${REDIS_IMAGE_URL} --raw | jq -r '.manifests[] | select(.platform.architecture=="arm64") | .digest')

# Update the vars to be replaced in the spec template file.
sed -i "s/REPLACE_REDIS_CONTAINER_SHA_X86/${REDIS_IMAGE_SHA_X86}/g" microshift-gitops.spec.in
sed -i "s/REPLACE_REDIS_CONTAINER_SHA_ARM/${REDIS_IMAGE_SHA_ARM}/g" microshift-gitops.spec.in

# Update the final spec file.
sed -i "s/REPLACE_REDIS_CONTAINER_SHA_X86/${REDIS_IMAGE_SHA_X86}/g" microshift-gitops.spec
sed -i "s/REPLACE_REDIS_CONTAINER_SHA_ARM/${REDIS_IMAGE_SHA_ARM}/g" microshift-gitops.spec