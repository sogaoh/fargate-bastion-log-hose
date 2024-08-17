.PHONY:

help:
	cat Makefile

up:
	docker compose up -d
upb:
	docker compose up -d --build
down:
	docker compose down --remove-orphans
prune:
	docker system prune --volumes


# ECR build -> push
AMD64 := --platform linux/amd64
APPLICATION := bastion
NOW := $(shell date "+%Y%m%d-%H%M")
BLDARG_TZ := --build-arg=TZ=Asia/Tokyo
BLDARG_SLEEP_SECONDS := --build-arg=SLEEP_SECONDS=900
AWS_ACCOUNT_ID ?= $(shell echo $$AWS_ACCOUNT_ID)
AWS_REGION := ap-northeast-1
TAG := latest
DOCKERFILE := Dockerfile

build:
	docker build $(AMD64) --no-cache -t $(APPLICATION):$(TAG) -f ./container/$(DOCKERFILE) $(BLDARG_TZ) $(BLDARG_SLEEP_SECONDS) .
tag:
	docker tag $(APPLICATION):$(TAG) "$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APPLICATION):$(TAG)"
push:
	docker push "$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(APPLICATION):$(TAG)"


ecr-login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
ecr-pub-login:
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
