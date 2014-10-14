all: help

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
	@docker build --tag=${USER}/redmine .

quickstart:
	@echo "Starting redmine..."
	@docker run --name=redmine-demo -d -p 10080:80 \
		-v /var/run/docker.sock:/run/docker.sock \
		-v $(shell which docker):/bin/docker \
		${USER}/redmine:latest >/dev/null
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
