NAME = gamalan/phalcon-nginx
TAG = 7.3-prod-no-nginx
SHELL = /bin/bash
PHP_VERSION= 7.3
PHALCON_VERSION= 34
ARTIFACTS_IMAGE = gamalan/mkimage:php$(PHP_VERSION)-phalcon$(PHALCON_VERSION)

.PHONY: pre-build docker-build post-build clean build release push do-push post-push

build: pre-build docker-build post-build

pre-build:

post-build: clean

docker-build:
	docker pull $(ARTIFACTS_IMAGE)
	docker create --name extract $(ARTIFACTS_IMAGE)
	docker cp extract:/artifacts ./artifacts
	docker rm -f extract
	docker build -t $(NAME):php$(TAG)-phalcon$(PHALCON_VERSION) .

release: build push

push: do-push post-push

do-push:
	docker push $(NAME):php$(TAG)-phalcon$(PHALCON_VERSION)

post-push:

clean:
	rm -rf ./artifacts

# vim:ft=make:noet:ci:pi:sts=0:sw=4:ts=4:tw=78:fenc=utf-8:et
