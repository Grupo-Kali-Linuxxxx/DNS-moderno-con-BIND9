# Actividad 2: DNS Moderno con BIND9
## Infraestructura DNS Autoritativa, Replicación Segura con TSIG, Resolutor Cifrado DoT y Análisis Comparativo

**Universidad Privada Domingo Savio (UPDS)**  
**Facultad:** Ciencias y Tecnología — Ingeniería de Sistemas  
**Asignatura:** Tecnología Web I (SIS-0150)  
**Docente Guía:** M.Sc. Ing. Jimmy Nataniel Requena Llorentty  
**Fecha de Presentación:** 18 de Octubre de 2026  

---

## 👥 Equipo de Trabajo
1. **Charles Yourdan Conde Ugarteche** (Coordinador)
2. **Brian Alejandro Calás Despaigne**
3. **Ketfer Gianella Salazar**
4. **Marco Aurelio Barriga**
5. **Adaniel Balderrama Orellana**

---

## 📋 Descripción del Proyecto e Instrucciones Institucionales

El objetivo de esta actividad es diseñar, desplegar, asegurar y auditar de forma autónoma la infraestructura DNS corporativa para la **Unidad Educativa Horizonte** (`horizonte.internal`, subred `10.10.10.0/24`), integrando los aprendizajes de los Laboratorios 6, 7 y 8:

- **Laboratorio 6:** Análisis de resoluciones reales con `dig +trace`, árbol jerárquico mundial (raíz -> TLD -> autoritativo), diseño de registros canónicos (`SOA`, `NS`, `A`, `AAAA`, `CNAME`, `MX`, `TXT/SPF`, `CAA`, `PTR`) y justificación de parámetros temporales de TTL y SOA (RFC 1912 / 1982).
- **Laboratorio 7:** Despliegue de BIND 9.18 primario (`ns1`) y secundario (`ns2`), zona directa e inversa, validación estricta con `named-checkconf` y `named-checkzone`, y transferencia segura punto a punto mediante firmas de transacciones **TSIG** con algoritmo `hmac-sha256` (RFC 2845) y notificaciones automáticas `NOTIFY`.
- **Laboratorio 8:** Resolutor recursivo perimetral **Unbound** (`10.10.10.4`) con memoria caché, validación DNSSEC, cifrado ascendente **DNS sobre TLS (DoT en puerto 853)** hacia Cloudflare/Quad9 y filtrado perimetral contra malware mediante Zonas de Políticas de Respuesta (**RPZ**).
- **Cuadro Comparativo Multidimensional:** Análisis técnico y económico entre el stack libre BIND9/Unbound en Linux vs Microsoft Windows Server DNS integrado en Active Directory vs DNS gestionado en la nube.
- **Automatización Propia:** Script en Bash (`verificar_autonomia_dns.sh`) que valida de extremo a extremo **18 pruebas técnicas automatizadas** superadas con éxito (100%).

---

## 🏗️ Arquitectura de Red y Topología de Contenedores

La infraestructura se orquesta mediante Docker Compose en una red privada aislada (`horizonte: 10.10.10.0/24`):

| Nodo | Rol Técnico | IP Privada | Software / Función Principal |
|---|---|---|---|
| `ns1` | Autoritativo Primario | `10.10.10.2` | BIND 9.18 — Custodia maestro de zonas `horizonte.internal` y `10.10.10.in-addr.arpa`. `recursion no;`. |
| `ns2` | Autoritativo Secundario | `10.10.10.3` | BIND 9.18 — Réplica tolerante a fallos sincronizada mediante TSIG (`transferencia-horizonte`) y NOTIFY. |
| `resolutor` | Resolutor Recursivo | `10.10.10.4` | Unbound — Atiende a clientes de la LAN, caché local, DoT en puerto 853 y filtrado RPZ. |
| `cliente` | Estación de Trabajo | `10.10.10.50` | Terminal Ubuntu 24.04 con herramientas de diagnóstico (`dig`, `nslookup`, `curl`). |

---

## 🚀 Puesta en Marcha Rápida (Guía de Ejecución)

### 1. Clonar el Repositorio
```bash
git clone https://github.com/Grupo-Kali-Linuxxxx/DNS-moderno-con-BIND9.git
cd DNS-moderno-con-BIND9
```

### 2. Levantar la Red de Contenedores
```bash
cd red_dns
docker compose -p tw1-dns up -d cliente ns1 ns2 resolutor
docker compose -p tw1-dns ps
```

### 3. Ejecutar la Auditoría Automatizada (18 de 18 Pruebas)
Desde la terminal del host (PowerShell o Bash):
```bash
docker compose -p tw1-dns exec cliente bash /lab/actividad02/scripts/verificar_autonomia_dns.sh
```

---

## 📄 Estructura de Entregables del Repositorio

- **`00_ENTREGABLES_PDF/`**
  - [`Actividad2_Informe_Tecnico_APA7.pdf`](00_ENTREGABLES_PDF/Actividad2_Informe_Tecnico_APA7.pdf): Informe técnico formal en formato APA 7ma edición (11 páginas, 6 figuras de evidencias reales de laboratorio, tablas y 8 referencias).
  - [`Actividad2_Bitacora_IA_APA7.pdf`](00_ENTREGABLES_PDF/Actividad2_Bitacora_IA_APA7.pdf): Bitácora de Inteligencia Artificial con declaración ética, registro de 4 sesiones de prompts con validación empírica y reporte de pruebas.
- **`actividad02/`**
  - [`INFORME_TECNICO_APA7.md`](actividad02/INFORME_TECNICO_APA7.md): Documento fuente Markdown del informe técnico.
  - [`BITACORA_IA_APA7.md`](actividad02/BITACORA_IA_APA7.md): Documento fuente Markdown de la bitácora de IA.
  - [`GUIA_DEFENSA_Y_PENDIENTES.md`](actividad02/GUIA_DEFENSA_Y_PENDIENTES.md): Guion de exposición de 10-15 minutos y banco de preguntas típicas del docente con respuestas clave.
  - `presentacion/index.html`: Diapositivas interactivas en HTML5 y CSS moderno (12 diapositivas con modo oscuro y atajos de teclado `←` / `→`).
  - `scripts/verificar_autonomia_dns.sh`: Script en Bash de verificación de 18 comprobaciones.
  - `evidencias/`: 6 capturas de pantalla de evidencias técnicas del entorno de laboratorio.
- **`red_dns/`**: Configuración de Docker Compose (`docker-compose.yml`) y `Dockerfile`.
- **`lab07/`**: Configuraciones de BIND9 para servidor primario (`ns1`), secundario (`ns2`) y clave TSIG.
- **`lab08/`**: Configuraciones de Unbound para resolutor recursivo, DoT :853 y políticas RPZ.
