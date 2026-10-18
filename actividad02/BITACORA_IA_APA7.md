# BITÁCORA DE INTELIGENCIA ARTIFICIAL: REGISTRO DE CONSULTAS, VALIDACIÓN CRIPTOGRÁFICA Y AUTOMATIZACIÓN DE INFRAESTRUCTURA DNS CON BIND9

**Actividad 2: DNS Moderno con BIND9**  
**Asignatura:** Tecnología Web I (SIS-0150)  
**Institución:** Universidad Privada Domingo Savio (UPDS) — Facultad de Ciencias y Tecnología  

---

**Autores:**  
1. **Charles Yourdan Conde Ugarteche** (Coordinador)  
2. **Brian Alejandro Calás Despaigne**  
3. **Ketfer Gianella Salazar**  
4. **Marco Aurelio Barriga**  
5. **Adaniel Balderrama Orellana**  

**Docente Evaluador:**  
M.Sc. Ing. Jimmy Nataniel Requena Llorentty  

**Fecha:**  
18 de Octubre de 2026  

**Repositorio Oficial de Código (GitHub):**  
[https://github.com/Grupo-Kali-Linuxxxx/DNS-moderno-con-BIND9](https://github.com/Grupo-Kali-Linuxxxx/DNS-moderno-con-BIND9)  

---

## 1. Declaración de Uso Ético y Metodología de IA

En concordancia con los lineamientos de evaluación institucional y la normativa ética de la Universidad Privada Domingo Savio, el uso de herramientas de Inteligencia Artificial Generativa se limitó estrictamente a labores de:
1. **Asistencia técnica conceptual:** Explicación matemática de algoritmos de serialización SOA (RFC 1982) y firmas criptográficas TSIG (RFC 2845).
2. **Depuración y análisis de sintaxis:** Interpretación de mensajes de error de `named-checkzone` y opciones de seguridad en BIND 9.18.
3. **Optimización de scripts de auditoría:** Estructuración modular y manejo de trampas (*traps*) de señales en Bash para el script de verificación automatizada.

Toda sugerencia o bloque de código provisto por la IA fue rigurosamente contrastado y validado de manera empírica en el laboratorio con las herramientas oficiales del estándar DNS (`dig`, `named-checkconf`, `named-checkzone` y `journalctl`).

---

## 2. Registro Cronológico de Interacción con la IA

### Sesión 1: Modelado de Registros y Trampa del Punto Final en Zonas Inversas
- **Prompt enviado a la IA:**  
  > *"En BIND9, ¿por qué es obligatorio colocar el punto final al final del FQDN en un registro PTR dentro de una zona inversa `10.10.10.in-addr.arpa`, y qué error se produce en producción si se omite?"*
- **Respuesta y Síntesis de la IA:**  
  La IA explicó la mecánica de expansión de nombres del RFC 1035: cualquier etiqueta que carezca de un punto final es interpretada por BIND como un nombre relativo al origen actual (`$ORIGIN`). En una zona inversa con `$ORIGIN 10.10.10.in-addr.arpa.`, omitir el punto en `mail.horizonte.internal` causa que BIND lo expanda a `mail.horizonte.internal.10.10.10.in-addr.arpa.`, destruyendo la resolución inversa y provocando el rechazo de correos en servidores destinatarios.
- **Validación del Estudiante:**  
  Se verificó la hipótesis ejecutando `named-checkzone 10.10.10.in-addr.arpa` sobre un archivo de prueba deliberadamente erróneo, corroborando el comportamiento exacto.

---

### Sesión 2: Seguridad en Transferencias de Zona: TSIG vs Restricción por IP
- **Prompt enviado a la IA:**  
  > *"¿Por qué la directiva `allow-transfer { 10.10.10.3; }` se considera insuficiente en entornos corporativos modernos y cómo la firma de transacción TSIG (RFC 2845) con `hmac-sha256` neutraliza ataques de spoofing y replay?"*
- **Respuesta y Síntesis de la IA:**  
  La IA detalló que los paquetes UDP y TCP pueden ser falsificados en capa de red mediante suplantación de cabeceras IP (*IP spoofing*). TSIG agrega un registro de recurso especial de pseudo-cabecera al final del mensaje que contiene un hash HMAC calculado con la clave simétrica y una marca de tiempo (*timestamp*). Si un atacante intenta inyectar o reproducir un paquete previo, el hash no coincide o el tiempo de tolerancia (300s) expira, rechazando la transferencia.
- **Validación del Estudiante:**  
  Se ejecutó `dig @10.10.10.2 horizonte.internal AXFR` sin clave, confirmando el rechazo inmediato `; Transfer failed.`, y luego con `-k transferencia.key`, logrando la transferencia autorizada de 17 registros.

---

### Sesión 3: Desarrollo del Script de Auditoría Automatizada Propio
- **Prompt enviado a la IA:**  
  > *"Ayúdame a estructurar un script de Bash para auditar de forma autónoma una red con BIND9 primario y secundario, que verifique código de salida, banderas de autoridad (aa), consistencia de seriales y rechazo de recursión, con colores ANSI y resumen de pruebas."*
- **Respuesta y Síntesis de la IA:**  
  Se propuso una arquitectura modular en tres fases con una función auxiliar `probar()`, captura de seriales mediante `awk` y evaluación booleana estricta `set -u`.
- **Validación del Estudiante:**  
  El equipo adaptó el script, integró las rutas reales de los contenedores Docker en `/lab/actividad02/scripts/verificar_autonomia_dns.sh` y comprobó que supere las 18 pruebas con código de retorno `0`.

---

### Sesión 4: Análisis Comparativo BIND9 vs Windows Server DNS
- **Prompt enviado a la IA:**  
  > *"Elabora una tabla comparativa exhaustiva entre BIND9 en Linux y el DNS de Windows Server integrado en Active Directory, abarcando modelo de almacenamiento, replicación, filtrado de seguridad, licenciamiento y administración."*
- **Respuesta y Síntesis de la IA:**  
  Se contrastaron las zonas en archivos planos y replicación NOTIFY/AXFR/TSIG de Linux frente a las particiones de aplicación NTDS.DIT y replicación RPC multimaster de Active Directory, junto con las diferencias entre políticas RPZ y directivas de resolución de consultas (*DNS Policies*).

---

## 3. Comprobación Oficial Automatizada del Entorno (18 de 18 Pruebas)

> 📌 **Cumplimiento de la Directriz Docente:**  
> La salida completa de la verificación final se documenta aquí en la Bitácora de IA para certificar el funcionamiento de todo el laboratorio y la actividad.

```text
==================================================================
   AUDITORÍA AUTOMATIZADA DE INFRAESTRUCTURA DNS - ACTIVIDAD 2
   Organización: U.E. Horizonte | Dominio: horizonte.internal
   Estudiante: Charles Yourdan Conde Ugarteche & Grupo
   Fecha de Ejecución: 18/10/2026
==================================================================

--- FASE 1: Comprobación de Registros de Zona Directa e Inversa (ns1) ---
  [OK] Registro A (raíz): horizonte.internal -> 10.10.10.20
  [OK] Registro A (web): www.horizonte.internal -> 10.10.10.20
  [OK] Registro CNAME (alias): portal.horizonte.internal -> www.horizonte.internal.
  [OK] Registro MX (correo): horizonte.internal -> 10 mail.horizonte.internal.
  [OK] Registro A (servidor de correo): mail.horizonte.internal -> 10.10.10.25
  [OK] Registro TXT (política SPF estricta): v=spf1 mx -all
  [OK] Registro CAA (autoridad certificadora): issue "horizonte.internal"
  [OK] Registro Inverso PTR: 10.10.10.20 -> www.horizonte.internal.
  [OK] Registro Inverso PTR: 10.10.10.25 -> mail.horizonte.internal.
  [OK] Bandera de Autoridad (aa flag) activa en ns1

--- FASE 2: Sincronización y Servidor Secundario (ns2) ---
  [OK] Respuesta autoritativa desde el Secundario (ns2 aa flag)
  [OK] Resolución en ns2 de CNAME encadenado hasta IP (portal -> 10.10.10.20)
  [OK] Resolución de Inversa PTR en el Secundario (ns2: 10.10.10.25)
  [OK] Consistencia de Número de Serie SOA (ns1=2026100701 vs ns2=2026100701)

--- FASE 3: Seguridad Perimetral, TSIG y Recursión ---
  [OK] Transferencia de Zona (AXFR) SIN clave TSIG -> Rechazada (Transfer failed)
  [OK] Transferencia de Zona (AXFR) CON clave TSIG -> Exitosa y Autenticada
  [OK] Rechazo de Recursión externa (ns1 responde REFUSED a dominios ajenos)
  [OK] Ofuscación de Versión de BIND (CH TXT version.bind -> 'no disponible')

==================================================================
   RESULTADO FINAL: 18 de 18 PRUEBAS SUPERADAS CON ÉXITO (100%)
   Estado: Infraestructura DNS lista para Defensa y Evaluación.
==================================================================
```

---

## 4. Referencias (APA v7)

- Internet Systems Consortium. (2024). *BIND 9 Administrator Reference Manual (ARM)*. ISC. https://bind9.readthedocs.io/
- Microsoft Corporation. (2023). *DNS policies overview in Windows Server*. Microsoft Learn. https://learn.microsoft.com/
- Vixie, P., Gudmundsson, O., Eastlake, D., & Wellington, B. (2000). *Secret key transaction authentication for DNS (TSIG)* (RFC 2845). IETF. https://doi.org/10.17487/RFC2845
