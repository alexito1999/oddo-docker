# Sistema de Impresión del Módulo POS (TPV) - Odoo 18

Estructura completa del sistema de impresión de tickets y preparación (cocina/barra).

---

## 1. Backend - Modelos Python

### `point_of_sale/models/pos_printer.py`
- **Modelo:** `pos.printer`
- **Función:** Define las impresoras de preparación (cocina/barra). Campos: `name`, `printer_type` (`iot`), `proxy_ip` (IP del IoT Box), `product_categories_ids` (filtro por categoría de producto).

### `point_of_sale/models/pos_config.py`
- **Modelo:** `pos.config`
- **Función:** Configuración general del POS. Campos relevantes:
  - `printer_ids` → impresoras de preparación asignadas
  - `is_order_printer` → habilita impresión de cocina
  - `iface_print_via_proxy` → usar IoT Box para imprimir
  - `iface_print_auto` → impresión automática al cobrar
  - `iface_print_skip_screen` → saltar pantalla de recibo si se imprime auto
  - `receipt_header` / `receipt_footer` → texto personalizado del ticket
  - `other_devices` → permite conexión HTTP sin IoT Box

### `point_of_sale/models/pos_order.py`
- **Función:** Modelo `pos.order`. Métodos:
  - `action_send_receipt()` → envía el recibo por email (genera imagen JPEG, la adjunta y envía via `mail.mail`)
  - `_prepare_mail_values()` / `_add_mail_attachment()` → prepara datos del email

### `hw_drivers/iot_handlers/drivers/PrinterDriver_L.py`
- **Función:** Driver de impresión para IoT Box en Linux. Recibe imagen base64, la convierte a blanco y negro, la formatea según protocolo (`star` o `escpos`), y la envía a la impresora via CUWS (`lp -d printer_identifier`).

### `hw_drivers/iot_handlers/drivers/PrinterDriver_W.py`
- **Función:** Driver de impresión para IoT Box en Windows. Equivalente al de Linux pero para Windows.

### `hw_drivers/iot_handlers/interfaces/PrinterInterface_L.py`
- **Función:** Interfaz de descubrimiento de impresoras en Linux via CUPS. Detecta impresoras USB, red (socket, LPD, DNSSD).

### `hw_drivers/controllers/proxy.py`
- **Función:** `ProxyController`. Rutas: `/hw_proxy/hello`, `/hw_proxy/handshake`, `/hw_proxy/status_json`. Gestiona la comunicación entre el POS y el IoT Box.

### `hw_escpos/controllers/main.py`
- **Función:** Controlador legacy ESC/POS. Rutas:
  - `/hw_proxy/open_cashbox` → abre el cajón de dinero
  - `/hw_proxy/print_receipt` → imprime recibo
  - `/hw_proxy/print_xml_receipt` → imprime recibo desde XML
  Procesa tareas en un hilo separado con cola.

### `hw_escpos/escpos/printer.py`
- **Función:** Clases de conexión física para impresoras ESC/POS:
  - `Usb` → conexión USB directa (pyusb)
  - `Serial` → conexión RS-232
  - `Network` → conexión TCP/IP (puerto 9100)

### `hw_escpos/escpos/escpos.py`
- **Función:** Clase base `Escpos` con comandos ESC/POS (corte, énfasis, alineación, código de barras, etc.), `StyleStack` (pila de estilos), `XmlSerializer` (serializa XML a comandos ESC/POS).

### `point_of_sale/controllers/main.py`
- **Función:** Controlador del POS. Rutas: `/pos/web`, `/pos/ui`, `/pos/ticket`, `/pos/ticket/validate`. Sirve la interfaz web y gestiona la visualización de tickets.

---

## 2. Frontend - JavaScript (OWL)

### `point_of_sale/static/src/app/store/pos_store.js`
- **Función:** `PosStore`. Métodos principales de impresión:
  - `printReceipt()` → imprime el recibo de la orden actual
  - `printReceipts()` → imprime múltiples recibos
  - `sendOrderInPreparation()` → envía cambios a cocina/barra
  - `printChanges()` → imprime los cambios de un pedido en la impresora correspondiente
  - `create_printer()` → crea instancia de `HWPrinter` según la configuración
  - `orderExportForPrinting()` → prepara datos de la orden para imprimir

### `point_of_sale/static/src/app/printer/base_printer.js`
- **Función:** `BasePrinter`. Clase base de impresión. Convierte HTML a canvas (JPEG) con `htmlToCanvas()`, mantiene cola de impresión, llama a `sendPrintingJob()`.

### `point_of_sale/static/src/app/printer/hw_printer.js`
- **Función:** `HWPrinter` (hereda de `BasePrinter`). Envía la imagen al IoT Box via RPC:
  - `sendPrintingJob(img)` → `sendAction({action: "print_receipt", receipt: img})`
  - `openCashbox()` → `sendAction({action: "cashbox"})`
  - La URL se forma con la IP del proxy (`this.url`)

### `point_of_sale/static/src/app/printer/printer_service.js`
- **Función:** `PrinterService`. Servicio core de impresión:
  - `setPrinter(newDevice)` → configura el device activo
  - `printHtml(el)` → usa el device configurado, con fallback a `printWeb()`
  - `printWeb(el)` → `window.print()` del navegador
  - `print(component, props)` → renderiza componente OWL a HTML e imprime

### `point_of_sale/static/src/app/printer/pos_printer_service.js`
- **Función:** `PosPrinterService` (hereda de `PrinterService`). Obtiene el device desde `hardware_proxy.printer`, reintenta con fallback si falla, muestra diálogo de error.

### `point_of_sale/static/src/app/printer/render_service.js`
- **Función:** `RenderService`. Convierte componentes OWL a HTML/canvas/JPEG:
  - `toHtml(component, props)` → renderiza a DOM
  - `toCanvas(component, props)` → renderiza a canvas
  - `toJpeg(component, props)` → renderiza a JPEG base64
  - `whenMounted({el, callback})` → ejecuta callback cuando el elemento está en DOM

### `point_of_sale/static/src/app/models/pos_order.js`
- **Función:** Modelo `pos.order` (frontend). Método `export_for_printing()` → construye el objeto con datos del ticket: líneas, impuestos, pagos, descuentos, cambio, cabecera (empresa, cajero), footer.

### `point_of_sale/static/src/app/screens/receipt_screen/receipt_screen.js`
- **Función:** Pantalla de recibo post-venta. Muestra el ticket, dispara la impresión automática, permite reimprimir, enviar por email.

### `point_of_sale/static/src/app/screens/receipt_screen/receipt/order_receipt.js`
- **Función:** Componente OWL `OrderReceipt`. Renderiza el contenido del ticket (productos, totales, cliente, etc.).

### `point_of_sale/static/src/app/screens/receipt_screen/receipt/receipt_header/receipt_header.js`
- **Función:** Componente OWL `ReceiptHeader`. Renderiza la cabecera del recibo (logo, empresa, dirección, etc.).

---

## 3. Vistas XML / Templates

### `point_of_sale/views/pos_printer_view.xml`
- **Función:** Vista formulario y tree del modelo `pos.printer`. Configuración de impresoras de preparación.

### `point_of_sale/views/pos_ticket_view.xml`
- **Función:** Vista de ticket (visualización en backend).

### `point_of_sale/static/src/app/screens/receipt_screen/receipt/order_receipt.xml`
- **Función:** Template QWeb del recibo. Estructura HTML del ticket que se renderiza y se envía a la impresora.

### `point_of_sale/static/src/app/store/order_change_receipt_template.xml`
- **Función:** Template QWeb para los cambios de pedido (cocina/barra). Muestra solo las líneas nuevas, canceladas o modificadas.

### `pos_loyalty/static/src/overrides/components/order_receipt/order_receipt.xml`
- **Función:** Extensión del template `OrderReceipt` para loyalty. Añade puntos de fidelidad, cupones generados y código de barras.

---

## 4. Flujo General

```
Venta Completada
       │
       ▼
ReceiptScreen
       │
       ├──→ printReceipt()
       │        │
       │        ▼
       │   PosPrinterService.print(OrderReceipt, data)
       │        │
       │        ├──→ RenderService.toHtml() → HTML
       │        │
       │        └──→ printHtml(html)
       │                 │
       │                 ├── [sin IoT Box] → window.print()
       │                 │
       │                 └── [con IoT Box]
       │                        │
       │                        ▼
       │                   BasePrinter.htmlToCanvas() → JPEG
       │                        │
       │                        ▼
       │                   HWPrinter.sendPrintingJob(img)
       │                        │
       │                        ▼
       │                   RPC /hw_proxy/default_printer_action
       │                        │
       │                        ▼
       │                   PrinterDriver_L (CUPS)
       │                        │
       │                        ▼
       │                   Impresora Física
       │
       └──→ action_send_receipt()  (email)
                │
                ▼
           Genera JPEG → mail.mail → cliente
```

```
Modificación Pedido (Restaurante)
       │
       ▼
sendOrderInPreparation()
       │
       ▼
getOrderChanges() → {new, cancelled, noteUpdated}
       │
       ▼
printChanges(order, changes)
       │
       ▼
[por cada impresora en printer_ids]
       │
       ├── filtra líneas por product_categories_ids
       │
       └── renderiza OrderChangeReceipt
            │
            └── mismo flujo de HWPrinter → IoT Box → Impresora
```
