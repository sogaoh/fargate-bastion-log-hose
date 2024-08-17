.PHONY:

help:
	cat Makefile

ecr-pub-login:
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

up:
	docker compose up -d
upb:
	docker compose up -d --build
down:
	docker compose down --remove-orphans
prune:
	docker system prune --volumes
