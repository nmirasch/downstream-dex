# Tool to build the container image. It can be either docker or podman
CONTAINER_RUNTIME ?= docker

IMAGE ?= registry.redhat.io/openshift-gitops-1/argocd-agent-principal-rhel8:dev

build-plugin:
	$(CONTAINER_RUNTIME) build -t $(IMAGE) -f ./Containerfile.plugin .

# Update the argocd-agent submodule to a specific commit or tag
update-argocd-agent:
	@if [ -z "$(ref)" ]; then \
		echo "Usage: make update-argocd-agent ref=<commit-or-tag>"; \
		exit 1; \
	fi
	@if [ ! -d "./argocd-agent/.git" ]; then \
		echo "Error: 'argocd-agent' submodule is not initialized or not a valid submodule."; \
		echo "To initialize the submodule, run:"; \
		echo "    git submodule update --init --recursive"; \
		exit 1; \
	fi
	cd argocd-agent && \
	git fetch origin || { echo "Error: Failed to fetch updates for argocd-agent submodule"; exit 1; } && \
	git checkout $(ref) || { echo "Error: Failed to checkout $(ref) in argocd-agent submodule"; exit 1; } && \
	cd .. && \
	git add argocd-agent || { echo "Error: Failed to stage updated submodule"; exit 1; } && \
	echo "Successfully updated argocd-agent submodule to $(ref)"

# Generate rpms.lock.yaml file
# Use upstream container image for rpm-lockfile-prototype tool when available
# Ref: https://github.com/konflux-ci/rpm-lockfile-prototype/pull/34
generate-rpms-lock:
	$(CONTAINER_RUNTIME) run \
		-v $$PWD/deps/rpms:/tmp \
		-w /tmp \
		--rm -t \
		quay.io/svghadi/rpm-lockfile-prototype:latest \
		--image registry.access.redhat.com/ubi8/ubi-minimal \
		--arch x86_64 --arch aarch64 --arch ppc64le --arch s390x \
		rpms.in.yaml