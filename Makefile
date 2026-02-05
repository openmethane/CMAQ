.phony: build
build: Dockerfile ## build an x86_64 version of the docker container
	docker build . -t cmaq

.phony: test
test: build
	docker run -it --rm -v ./tests:/opt/tests cmaq /opt/tests/test-all.sh
