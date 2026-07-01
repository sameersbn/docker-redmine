IMAGE:=sameersbn/redmine
CERTS_DIR=certs
CERT_FILES=$(CERTS_DIR)/redmine.crt $(CERTS_DIR)/dhparam.pem

.PHONY: test-release test-compose-matrix generate-certs clean

# Test stack uses throwaway named volumes (see docker-compose.testvols.yml) so
# the release smoke test doesn't need sudo and always starts clean.
COMPOSE_TEST := docker compose -f docker-compose.yml -f test/docker-compose.testvols.yml -f test/docker-compose.postgresvols.yml

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
	@docker build --tag=$(IMAGE) .


test-release: generate-certs
	@echo "Clean old run (throwaway volumes, no sudo)"
	$(COMPOSE_TEST) down -v --remove-orphans
	$(COMPOSE_TEST) build
	$(COMPOSE_TEST) up

# Smoke-test each locally-runnable compose file with throwaway volumes.
# Recommended for major-version releases. Pass FILES="..." to override the set.
test-compose-matrix: generate-certs
	./test/smoke-compose.sh $(FILES)

generate-certs: $(CERT_FILES)

$(CERTS_DIR):
	mkdir -p $(CERTS_DIR)

$(CERTS_DIR)/redmine.key: | $(CERTS_DIR)
	openssl genrsa -out $(CERTS_DIR)/redmine.key 2048

$(CERTS_DIR)/redmine.csr: $(CERTS_DIR)/redmine.key
	openssl req -new -key $(CERTS_DIR)/redmine.key -out $(CERTS_DIR)/redmine.csr

$(CERTS_DIR)/redmine.crt: $(CERTS_DIR)/redmine.csr $(CERTS_DIR)/redmine.key
	openssl x509 -req -days 365 -in $(CERTS_DIR)/redmine.csr -signkey $(CERTS_DIR)/redmine.key -out $(CERTS_DIR)/redmine.crt

$(CERTS_DIR)/dhparam.pem: | $(CERTS_DIR)
	openssl dhparam -out $(CERTS_DIR)/dhparam.pem 2048

clean:
	rm -rf $(CERTS_DIR)

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
