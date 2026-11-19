# shellcheck disable=SC2034
# NOTE: this is a Makefile, not shell. $(VAR) is Make syntax.
NAME=gamalan/phalcon-nginx
TAG=php7.3-sury-prod-phalcon34

build:
	docker build -t $(NAME):$(TAG) .

# Full fresh rebuild: re-runs apt (picks up new Sury/Debian security
# builds) and recompiles extensions. Plain `build` reuses cached layers,
# which silently keeps old PHP packages and old configs.
rebuild:
	docker build --pull --no-cache -t $(NAME):$(TAG) .

run:
	docker run --rm -p 8080:80 -v $(PWD)/../sample:/app/public $(NAME):$(TAG)

shell:
	docker run --rm -it $(NAME):$(TAG) bash

push:
	docker push $(NAME):$(TAG)
