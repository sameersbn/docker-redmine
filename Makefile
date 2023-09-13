IMAGE:=sameersbn/redmine
all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build       - build the redmine image"
	@echo "   2. make quickstart  - start redmine"
	@echo "   3. make stop        - stop redmine"
	@echo "   4. make logs        - view logs"
	@echo "   5. make purge       - stop and remove the container"

build:
	@docker buildx build --platform=linux/amd64,linux/arm64 --tag=$(IMAGE) .

test-release:
	@echo Clean old run
	sudo rm -rf /srv/docker/redmine/
	sudo mkdir -p /src/docker/redmine/redmine
	sudo cp -rf certs /src/docker/redmine/redmine/
	docker-compose down
	docker-compose build
	docker-compose up

release:
	./make_release.sh
	@echo "Open https://github.com/sameersbn/docker-redmine/releases and Draft new release"

quickstart:
	@echo "Starting redmine..."
	@docker run --name=redmine-demo -d -p 10080:80 \
		-v /var/run/docker.sock:/run/docker.sock \
		-v $(shell which docker):/bin/docker \
		$(IMAGE) >/dev/null
	@echo "Please be patient. This could take a while..."
	@echo "Redmine will be available at http://localhost:10080"
	@echo "Type 'make logs' for the logs"

stop:
	@echo "Stopping redmine..."
	@docker stop redmine-demo >/dev/null

purge: stop
	@echo "Removing stopped container..."
	@docker rm redmine-demo >/dev/null

logs:
	@docker logs -f redmine-demo
