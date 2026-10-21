# shellcheck disable=SC2034
# NOTE: this is a Makefile, not shell. $(VAR) is Make syntax.
NAME=gamalan/phalcon-nginx
TAG=php7.3-sury-prod-phalcon34

build:
	docker build -t $(NAME):$(TAG) .

run:
	docker run --rm -p 8080:80 -v $(PWD)/../sample:/app/public $(NAME):$(TAG)

shell:
	docker run --rm -it $(NAME):$(TAG) bash

push:
	docker push $(NAME):$(TAG)
