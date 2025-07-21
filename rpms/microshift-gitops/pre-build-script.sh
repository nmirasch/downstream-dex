#!/bin/bash
set -euxo pipefail

echo "INFO: Validating required environment variables for image tags..."

# Variables que esperamos de la pipeline (más simples que antes)
if [ -z "${ARGO_CD_IMAGE_URL_WITH_TAG}" ] || [ -z "${REDIS_IMAGE_URL_WITH_TAG}" ]; then
    echo "ERROR: Required variables not set."
    echo "Please define ARGO_CD_IMAGE_URL_WITH_TAG (e.g., registry.redhat.io/openshift-gitops-1/argocd-rhel9:gitops-1.17-rhel-9-candidate)"
    echo "and REDIS_IMAGE_URL_WITH_TAG (e.g., registry.redhat.io/rhel9/redis-6:rhel-9.3.0-container-released)."
    exit 1
fi

echo "INFO: Discovering image SHAs using skopeo..."

# Get the argocd container image url and its tag.
ARGO_CD_IMAGE_SHA_X86=$(skopeo inspect docker://${ARGO_CD_IMAGE_URL_WITH_TAG} --raw | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
ARGO_CD_IMAGE_SHA_ARM=$(skopeo inspect docker://${ARGO_CD_IMAGE_URL_WITH_TAG} --raw | jq -r '.manifests[] | select(.platform.architecture=="arm64") | .digest')

ARGO_CD_IMAGE_TAG=$(echo "${ARGO_CD_IMAGE_URL_WITH_TAG}" | cut -d':' -f2)
echo "INFO: ArgoCD x86 SHA: ${ARGO_CD_IMAGE_SHA_X86}"
echo "INFO: ArgoCD arm64 SHA: ${ARGO_CD_IMAGE_SHA_ARM}"

# Get the redis container image url and its tag.
REDIS_IMAGE_SHA_X86=$(skopeo inspect docker://${REDIS_IMAGE_URL_WITH_TAG} --raw | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest')
REDIS_IMAGE_SHA_ARM=$(skopeo inspect docker://${REDIS_IMAGE_URL_WITH_TAG} --raw | jq -r '.manifests[] | select(.platform.architecture=="arm64") | .digest')

echo "INFO: Redis x86 SHA: ${REDIS_IMAGE_SHA_X86}"
echo "INFO: Redis arm64 SHA: ${REDIS_IMAGE_SHA_ARM}"


echo "INFO: Generating microshift-gitops.spec from template..."
cp microshift-gitops.spec.in microshift-gitops.spec

sed -i "s|REPLACE_ARGO_CD_CONTAINER_SHA_X86|${ARGO_CD_IMAGE_SHA_X86}|g" microshift-gitops.spec.in
sed -i "s|REPLACE_ARGO_CD_CONTAINER_SHA_ARM|${ARGO_CD_IMAGE_SHA_ARM}|g" microshift-gitops.spec.in
sed -i "s|REPLACE_ARGO_CD_VERSION|${ARGO_CD_IMAGE_TAG}|g" microshift-gitops.spec.in
sed -i "s|REPLACE_REDIS_CONTAINER_SHA_X86|${REDIS_IMAGE_SHA_X86}|g" microshift-gitops.spec.in
sed -i "s|REPLACE_REDIS_CONTAINER_SHA_ARM|${REDIS_IMAGE_SHA_ARM}|g" microshift-gitops.spec.in

echo "INFO: Replacing placeholders in spec file..."
sed -i "s|REPLACE_ARGO_CD_CONTAINER_SHA_X86|${ARGO_CD_IMAGE_SHA_X86}|g" microshift-gitops.spec
sed -i "s|REPLACE_ARGO_CD_CONTAINER_SHA_ARM|${ARGO_CD_IMAGE_SHA_ARM}|g" microshift-gitops.spec
sed -i "s|REPLACE_ARGO_CD_VERSION|${ARGO_CD_IMAGE_TAG}|g" microshift-gitops.spec
sed -i "s|REPLACE_REDIS_CONTAINER_SHA_X86|${REDIS_IMAGE_SHA_X86}|g" microshift-gitops.spec
sed -i "s|REPLACE_REDIS_CONTAINER_SHA_ARM|${REDIS_IMAGE_SHA_ARM}|g" microshift-gitops.spec

echo "INFO: Final spec file generated."
cat microshift-gitops.spec
echo "------------------------------------------"
