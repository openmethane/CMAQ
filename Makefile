.phony: build
build: Dockerfile ## build both Debian packages into dist/
	docker build --target debs --output type=local,dest=dist \
		--build-arg DEB_VERSION=$$(scripts/debian-version.sh) .

.phony: test
test: ## install openmethane-cmaq in a clean image and run the tests
	docker build --target test --build-arg DEB_VERSION=$$(scripts/debian-version.sh) .
