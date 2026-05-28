FROM odoo:18

USER root

RUN pip install --no-cache-dir --break-system-packages watchdog debugpy

USER odoo
