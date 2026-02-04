.phony: build
build: Dockerfile ## build an x86_64 version of the docker container
	docker build . -t cmaq
