NAME = gamalan/php-nginx
TAG = 8.1-prod
SHELL = /bin/bash
PHP_VERSION= 8.1
PHALCON_VERSION= 34
ARTIFACTS_IMAGE = gamalan/mkimage:php$(PHP_VERSION)-phalcon$(PHALCON_VERSION)

.PHONY: pre-build docker-build post-build clean build release push do-push post-push

build: pre-build docker-build post-build

pre-build:

post-build: clean

docker-build:
	docker buildx build --network=host -t $(NAME):php$(TAG) .

release: build push

push: do-push post-push

do-push:
	docker push $(NAME):php$(TAG)

post-push:

clean:
	rm -rf ./artifacts

# vim:ft=make:noet:ci:pi:sts=0:sw=4:ts=4:tw=78:fenc=utf-8:et
