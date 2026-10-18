# Guía Maestra de Preparación, Pendientes y Defensa Grupal — Actividad 2
**Asignatura:** Tecnología Web I (SIS-0150)  
**Tema:** DNS Moderno con BIND9 (Primario, Secundario, TSIG, DoT y Comparativa)  
**Equipo de Trabajo:** Brian Alejandro Calás Despaigne, Charles Yourdan Conde Ugarteche, Ketfer Gianella Salazar, Marco Aurelio Barriga, Adaniel Balderrama Orellana  
**Docente Evaluador:** M.Sc. Ing. Jimmy Nataniel Requena Llorentty  

---

## 📌 1. Diagnóstico del Proyecto: ¿Qué está hecho y qué falta?

### ✅ Lo que YA ESTÁ HECHO (Listo para reutilizar)
1. **Laboratorio 6:** Análisis de resoluciones reales con `dig +trace`, jerarquía raíz -> TLD -> autoritativos, análisis de registros de salud de dominios (`cloudflare.com`, `wikipedia.org`, `upds.edu.bo`).
2. **Laboratorio 7:** Servidor BIND9 primario (`ns1` 10.10.10.2) y secundario (`ns2` 10.10.10.3), zona directa `horizonte.internal`, zona inversa `10.10.10.in-addr.arpa`, transferencia restringida con clave TSIG (`transferencia-horizonte`), NOTIFY activo y 16/16 comprobaciones aprobadas.
3. **Laboratorio 8:** Resolutor recursivo Unbound (`resolutor` 10.10.10.4) con caché, validación DNSSEC, salida cifrada por DoT (puerto 853) y filtrado RPZ.
4. **Script propio de automatización:** Creado en `actividad02/scripts/verificar_autonomia_dns.sh` para cumplir la rúbrica máxima (automatización propia).

---

### 📋 Lo que FALTA HACER (Checklist antes de exponer)

- [ ] **1. Preparar la laptop de tu compañero:**
  - Asegurar que tenga instalado **Docker Desktop** (en ejecución).
  - Copiar la carpeta completa del proyecto o clonar el repositorio de GitHub.
- [ ] **2. Rellenar los datos grupales:**
  - Colocar los nombres completos de todos los integrantes en la portada de [INFORME_TECNICO_APA7.md](file:///f:/tecnologia%20web%201/labs/actividad02/INFORME_TECNICO_APA7.md) y [BITACORA_IA_APA7.md](file:///f:/tecnologia%20web%201/labs/actividad02/BITACORA_IA_APA7.md).
  - Colocar el enlace exacto del repositorio GitHub del grupo.
- [ ] **3. Probar la presentación interactiva:**
  - Abrir con doble clic el archivo `actividad02/presentacion/index.html` en el navegador de la laptop para verificar que las diapositivas pasen con las teclas de flecha (`←` y `→`).
- [ ] **4. Ensayar los comandos de demostración en vivo (5 minutos):**
  - Ejecutar el script automatizado y las 4 consultas clave de la defensa que el docente suele pedir.

---

## 💻 2. Puesta a Punto en la Laptop del Compañero (Paso a Paso)

Sigue estos 3 pasos exactos en la computadora donde se proyectará la exposición:

### Paso 2.1: Iniciar Docker Desktop
- Abrir la aplicación **Docker Desktop** en Windows y esperar a que el icono se ponga en verde (**Engine running**).

### Paso 2.2: Levantar los contenedores de la red DNS
Abre **PowerShell** y navega a la carpeta del proyecto:

```powershell
# 1. Entrar a la carpeta de red
Set-Location "red_dns"

# 2. Iniciar los contenedores ns1, ns2, cliente y resolutor
docker compose -p tw1-dns up -d cliente ns1 ns2 resolutor

# 3. Comprobar que los 4 estén en estado "Up"
docker compose -p tw1-dns ps
```

### Paso 2.3: Ejecutar la prueba general en vivo
```powershell
docker compose -p tw1-dns exec cliente bash /lab/actividad02/scripts/verificar_autonomia_dns.sh
```
> *Si el script muestra todas las pruebas en verde `[OK]`, la laptop está lista para la defensa al 100%.*

---

## 🎤 3. Guion de Exposición Grupal y Defensa (10 a 15 Minutos)

Para lograr la nota máxima (**10/10 puntos** según la rúbrica), distribuyan los roles de exposición de la siguiente manera:

### 👤 Integrante 1: Introducción, Jerarquía y Diseño de Zona (Criterio 1 - 3 Puntos)
- **Diapositivas:** 1 a 4.
- **Qué explica:**
  - El problema original: los nombres estaban en el archivo `hosts` local de cada máquina, lo cual era inmanejable.
  - La jerarquía DNS explicada con el comando `dig +trace`: cómo la consulta viaja desde los servidores raíz (`.`), baja al TLD (`.bo` o `.internal`) y llega a los autoritativos.
  - El diseño de la zona `horizonte.internal`: registros `SOA`, `NS`, `A`, `CNAME`, `MX`, `TXT (SPF)` y `CAA`.
  - **Punto clave de rúbrica:** Justificar los valores del SOA (Serial `AAAAMMDDnn`, Refresh de 1h, Retry de 10m, Expire de 14 días y TTL negativo de 5m) y por qué un TTL bajo (3600s) es ideal durante despliegues iniciales.

---

### 👤 Integrante 2: Implementación en BIND9 y Verificación Automatizada (Criterio 2 - 3 Puntos)
- **Diapositivas:** 5 a 7.
- **Qué explica:**
  - Cómo se configuró BIND9 en `ns1` (10.10.10.2) para la zona directa e inversa.
  - Por qué las zonas inversas en BIND9 usan nombres canónicos con punto final (`mail.horizonte.internal.`) para no sufrir concatenación errónea de `$ORIGIN`.
  - Las herramientas de validación de sintaxis: `named-checkconf` y `named-checkzone`.
- **Demostración en vivo en pantalla:**
  Ejecutar en la terminal PowerShell:
  ```powershell
  docker compose -p tw1-dns exec ns1 named-checkzone horizonte.internal /var/lib/bind/db.horizonte.internal
  docker compose -p tw1-dns exec cliente bash /lab/actividad02/scripts/verificar_autonomia_dns.sh
  ```
  *(Mostrar el reporte automático con las 18 pruebas superadas).*

---

### 👤 Integrante 3: Servidor Secundario, Seguridad TSIG y DoT (Criterio 3 - 4 Puntos)
- **Diapositivas:** 8 a 10.
- **Qué explica:**
  - La sincronización automática mediante el mecanismo `NOTIFY` hacia `ns2` (10.10.10.3).
  - La seguridad criptográfica: cómo la clave **TSIG** (`hmac-sha256`) protege las transferencias de zona completa (AXFR), impidiendo que intrusos descarguen la base de datos de la escuela.
  - Demostrar el rechazo de recursión: `dig @10.10.10.2 google.com` -> `status: REFUSED`.
- **Demostración en vivo en pantalla:**
  ```powershell
  # 1. Demostrar que sin clave la transferencia falla
  docker compose -p tw1-dns exec cliente dig @10.10.10.2 horizonte.internal AXFR

  # 2. Demostrar que con clave TSIG la transferencia es exitosa
  docker compose -p tw1-dns exec cliente dig -k /lab/lab07/practica/compartido/transferencia.key @10.10.10.2 horizonte.internal AXFR
  ```

---

### 👤 Integrante 4 (o Grupo): Comparativa con Windows Server y Conclusiones
- **Diapositivas:** 11 a 13.
- **Qué explica:**
  - Cuadro comparativo entre BIND9/Unbound (Linux) y DNS de Windows Server / Active Directory:
    - *Almacenamiento:* Archivos de texto (`/var/lib/bind`) vs Partición de Directorio Activo integrada en LDAP.
    - *Replicación:* NOTIFY + AXFR/TSIG en Linux vs Replicación multimaster por DRA/RPC en Windows.
    - *Seguridad:* Zonas RPZ estándar en Linux vs DNS Policies de PowerShell en Windows.
    - *Costo:* Open source y alta flexibilidad vs Costos de licenciamiento por servidor y CALs de usuario.
  - Conclusiones institucionales y presentación del enlace al repositorio GitHub.

---

## ❓ 4. Banco de Preguntas Típicas del Docente (y Cómo Responderlas)

El docente **M.Sc. Ing. Jimmy Nataniel Requena Llorentty** suele hacer preguntas directas de criterio. Aquí tienen las respuestas exactas:

### P1: ¿Por qué desactivamos la recursión (`recursion no;`) en el servidor autoritativo `ns1`?
> **Respuesta:**  
> "Porque un servidor autoritativo solo debe responder por las zonas bajo su control directo. Si dejamos la recursión abierta a todo internet, atacantes pueden enviar consultas falsificando la IP de una víctima (spoofing) y usar nuestro servidor como reflector en ataques masivos de **DDoS por amplificación DNS**."

### P2: ¿Qué ocurre si un administrador añade un registro en `ns1` pero olvida incrementar el serial del SOA?
> **Respuesta:**  
> "El servidor secundario `ns2` no actualizará su copia de zona. Aunque reciba un aviso NOTIFY, `ns2` compara el serial del paquete con el que tiene en memoria; al ver que no es estrictamente mayor, descarta la transferencia asumiendo que ya está actualizado. Por ende, los clientes que consulten a `ns2` no verán el nuevo registro."

### P3: ¿Por qué en la zona inversa `db.10.10.10` es indispensable poner el punto final al final del nombre en el registro PTR?
> **Respuesta:**  
> "Porque en el estándar RFC 1035, cualquier nombre que no termine en punto es considerado relativo y BIND le anexa automáticamente el valor de `$ORIGIN`. Como en la inversa el origen es `10.10.10.in-addr.arpa.`, si escribiéramos `mail.horizonte.internal` sin punto, BIND generaría `mail.horizonte.internal.10.10.10.in-addr.arpa.`, rompiendo la resolución inversa."

### P4: ¿Qué ventaja ofrece una clave TSIG frente a restringir la transferencia solo por dirección IP (`allow-transfer { 10.10.10.3; }`)?
> **Respuesta:**  
> "Restringir por IP es vulnerable a ataques de falsificación de paquetes IP (*IP spoofing*) en redes de capa 2. TSIG utiliza una firma criptográfica simétrica (`hmac-sha256`) con una marca de tiempo (*timestamp*); el receptor valida matemáticamente la firma, garantizando autenticidad del origen e integridad total del paquete, haciendo imposible la suplantación."

### P5: Si el servidor primario `ns1` se apaga permanentemente, ¿cuánto tiempo sobrevive el DNS del colegio con `ns2`?
> **Respuesta:**  
> "Sobrevive exactamente **14 días** (1,209,600 segundos), que es el valor configurado en el parámetro `expire` del SOA. Durante ese lapso, `ns2` responde todas las consultas normalmente con su réplica en `/var/lib/bind/`. Al día 15, al no poder contactar al primario, `ns2` deja de responder con autoridad arrojando `SERVFAIL` para proteger contra datos indefinidamente obsoletos."
