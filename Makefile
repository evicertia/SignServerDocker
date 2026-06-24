NAME   := evicertia/signserver
TAG    := $$(git log -1 --pretty=%h)
IMG    := ${NAME}:${TAG}
LATEST := ${NAME}:latest
PLAT   := linux/amd64

build:
	@docker build --platform $(PLAT) -t ${IMG} .
	@docker tag ${IMG} ${LATEST}

push:
	@docker push ${NAME}

login:
	@docker log -u ${DOCKER_USER} -p ${DOCKER_PASS}
