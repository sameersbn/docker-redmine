IMAGE_REPO ?= sameersbn/redmine
FLAVOR ?= redmine
VERSION ?= 6.1.2

TZ ?= Asia/Tokyo

CERTS_DIR ?= certs
CERT_FILES := $(CERTS_DIR)/redmine.crt $(CERTS_DIR)/dhparam.pem

ifeq ($(FLAVOR),redmine)
APP_PORT ?= 10083
DB_NAME ?= redmine_production
else ifeq ($(FLAVOR),redmica)
APP_PORT ?= 10084
DB_NAME ?= redmica_production
else
$(error Unsupported FLAVOR '$(FLAVOR)'. Expected 'redmine' or 'redmica')
endif

IMAGE := $(IMAGE_REPO):$(FLAVOR)-$(VERSION)
PROJECT_NAME := redmine-$(FLAVOR)

BASE_DIR := /srv/docker/redmine
DATA_DIR := $(BASE_DIR)/$(FLAVOR)
LOG_DIR := $(BASE_DIR)/$(FLAVOR)-logs
POSTGRES_DATA_DIR := $(BASE_DIR)/$(FLAVOR)-postgresql

DB_HOST ?= postgresql
DB_PORT ?= 5432
DB_USER ?= redmine
DB_PASS ?= password

COMPOSE = COMPOSE_PROJECT_NAME=$(PROJECT_NAME) \
	IMAGE=$(IMAGE) \
	REDMINE_VERSION=$(VERSION) \
	REDMINE_FLAVOR=$(FLAVOR) \
	TZ=$(TZ) \
	APP_PORT=$(APP_PORT) \
	DATA_DIR=$(DATA_DIR) \
	LOG_DIR=$(LOG_DIR) \
	POSTGRES_DATA_DIR=$(POSTGRES_DATA_DIR) \
	DB_HOST=$(DB_HOST) \
	DB_PORT=$(DB_PORT) \
	DB_USER=$(DB_USER) \
	DB_PASS=$(DB_PASS) \
	DB_NAME=$(DB_NAME) \
	docker compose

TEST_RELEASE_COMPOSE = $(COMPOSE) -f docker-compose.yml -f docker-compose.test-release.yml

.PHONY: all help build up down logs config ps restart quickstart stop purge test-release prepare-dirs generate-certs clean release \
	build-redmine build-redmica up-redmine up-redmica down-redmine down-redmica logs-redmine logs-redmica config-redmine config-redmica

all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   make build FLAVOR=redmine VERSION=6.1.2"
	@echo "   make build FLAVOR=redmica VERSION=4.0.3"
	@echo "   make up FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083"
	@echo "   make up FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084"
	@echo "   make down FLAVOR=redmine"
	@echo "   make down FLAVOR=redmica"
	@echo "   make logs FLAVOR=redmine"
	@echo "   make logs FLAVOR=redmica"
	@echo ""
	@echo "   Preset shortcuts:"
	@echo "   make build-redmine"
	@echo "   make build-redmica"
	@echo "   make up-redmine"
	@echo "   make up-redmica"
	@echo ""

build:
	@docker build \
		--build-arg REDMINE_VERSION=$(VERSION) \
		--build-arg REDMINE_FLAVOR=$(FLAVOR) \
		--tag=$(IMAGE) .

prepare-dirs:
	sudo mkdir -p $(DATA_DIR) $(LOG_DIR) $(POSTGRES_DATA_DIR)

up: prepare-dirs
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

restart: down up

logs:
	@$(COMPOSE) logs -f

config:
	@$(COMPOSE) config

ps:
	@$(COMPOSE) ps

quickstart: up

stop: down

purge:
	@$(COMPOSE) down -v

test-release: generate-certs
	$(TEST_RELEASE_COMPOSE) down
	@echo "Checking existing test-release state"
	@if [ -e "$(DATA_DIR)" ]; then \
		echo "ERROR: $(DATA_DIR) already exists."; \
		echo "For a clean test-release run, back up or remove it manually first."; \
		exit 1; \
	fi
	sudo mkdir -p $(DATA_DIR)/certs
	sudo cp -f $(CERTS_DIR)/redmine.key $(DATA_DIR)/certs/
	sudo cp -f $(CERTS_DIR)/redmine.crt $(DATA_DIR)/certs/
	sudo cp -f $(CERTS_DIR)/dhparam.pem $(DATA_DIR)/certs/
	sudo chmod 400 $(DATA_DIR)/certs/redmine.key
	$(TEST_RELEASE_COMPOSE) down
	$(TEST_RELEASE_COMPOSE) config
	$(TEST_RELEASE_COMPOSE) build
	$(TEST_RELEASE_COMPOSE) up

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

build-redmine:
	$(MAKE) build FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083

build-redmica:
	$(MAKE) build FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084

up-redmine:
	$(MAKE) up FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083

up-redmica:
	$(MAKE) up FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084

down-redmine:
	$(MAKE) down FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083

down-redmica:
	$(MAKE) down FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084

logs-redmine:
	$(MAKE) logs FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083

logs-redmica:
	$(MAKE) logs FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084

config-redmine:
	$(MAKE) config FLAVOR=redmine VERSION=6.1.2 APP_PORT=10083

config-redmica:
	$(MAKE) config FLAVOR=redmica VERSION=4.0.3 APP_PORT=10084
