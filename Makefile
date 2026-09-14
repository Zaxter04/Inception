NAME = inception

COMPOSE = docker compose -f srcs/docker-compose.yml

DATA_DIR = $(HOME)/data
WP_DATA = $(DATA_DIR)/wordpress
DB_DATA = $(DATA_DIR)/mariadb


all: up

up:
	mkdir -p $(WP_DATA) $(DB_DATA)
	$(COMPOSE) up -d --build

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v
	docker system prune -af
	sudo rm -rf $(WP_DATA) $(DB_DATA)

re:
	$(MAKE) fclean
	$(MAKE) all


.PHONY: all up build down start stop restart logs ps clean fclean re