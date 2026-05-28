.PHONY: up down restart logs shell scaffold test

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart odoo

logs:
	docker compose logs -f odoo

shell:
	docker compose exec odoo /bin/bash

db-shell:
	docker compose exec db psql -U odoo

scaffold:
	@echo "Uso: make scaffold name=nombre_modulo"
	docker compose exec odoo odoo scaffold /mnt/extra-addons/$(name)

test:
	@echo "Uso: make test module=nombre_modulo"
	docker compose exec odoo odoo -d test --stop-after-init -i $(module) --test-enable

install:
	@echo "Uso: make install module=nombre_modulo db=nombre_db"
	docker compose exec odoo odoo -d $(db) --stop-after-init -i $(module)
