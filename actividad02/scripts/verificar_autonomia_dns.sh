#!/usr/bin/env bash
# ==============================================================================
# Script de Automatización y Verificación Integral de Zonas DNS BIND9
# Asignatura: Tecnología Web I (SIS-0150)
# Actividad 2: DNS Moderno con BIND9 (Primario, Secundario, TSIG y Seguridad)
# Integrantes: Charles Yourdan Conde Ugarteche, Brian Alejandro Calás Despaigne,
#              Ketfer Gianella Salazar, Marco Aurelio Barriga, Adaniel Balderrama Orellana
# ==============================================================================

set -u
trap 'echo -e "\n\033[1;31m[!] Verificación interrumpida por el usuario.\033[0m"; exit 1' INT

# Códigos ANSI para salida con colores
VERDE="\033[1;32m"
ROJO="\033[1;31m"
AZUL="\033[1;34m"
AMARILLO="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Direcciones IP y Parámetros del Entorno
NS1="10.10.10.2"
NS2="10.10.10.3"
DOMINIO="horizonte.internal"
CLAVE_TSIG="/lab/lab07/practica/compartido/transferencia.key"
[[ -f "$CLAVE_TSIG" ]] || CLAVE_TSIG="/lab/lab07/compartido/transferencia.key"

ok=0
total=0

probar() {
    local descripcion="$1"
    shift
    total=$((total + 1))
    echo -ne "  [..] Probando: ${descripcion}..."
    if "$@" >/dev/null 2>&1; then
        echo -e "\r  ${VERDE}[OK]${RESET} ${descripcion}"
        ok=$((ok + 1))
    else
        echo -e "\r  ${ROJO}[FALLO]${RESET} ${descripcion}"
    fi
}

echo -e "${AZUL}==================================================================${RESET}"
echo -e "${CYAN}   AUDITORÍA AUTOMATIZADA DE INFRAESTRUCTURA DNS - ACTIVIDAD 2${RESET}"
echo -e "   Organización: U.E. Horizonte | Dominio: ${DOMINIO}"
echo -e "   Equipo: Charles Conde, Brian Calás, Ketfer Salazar, Marco Barriga, Adaniel Balderrama"
echo -e "   Fecha de Ejecución: $(date '+%d/%m/%Y %H:%M:%S')"
echo -e "${AZUL}==================================================================${RESET}\n"

# ------------------------------------------------------------------------------
# FASE 1: Verificación de Registros en Servidor Primario (ns1)
# ------------------------------------------------------------------------------
echo -e "${AMARILLO}--- FASE 1: Comprobación de Registros de Zona Directa e Inversa (ns1) ---${RESET}"

probar "Registro A (raíz): ${DOMINIO} -> 10.10.10.20" \
    bash -c "dig +short @${NS1} ${DOMINIO} A | grep -qx '10.10.10.20'"

probar "Registro A (web): www.${DOMINIO} -> 10.10.10.20" \
    bash -c "dig +short @${NS1} www.${DOMINIO} A | grep -qx '10.10.10.20'"

probar "Registro CNAME (alias): portal.${DOMINIO} -> www.${DOMINIO}." \
    bash -c "dig +short @${NS1} portal.${DOMINIO} CNAME | grep -qi 'www.${DOMINIO}.'"

probar "Registro MX (correo): ${DOMINIO} -> 10 mail.${DOMINIO}." \
    bash -c "dig +short @${NS1} ${DOMINIO} MX | grep -qi '10 mail.${DOMINIO}.'"

probar "Registro A (servidor de correo): mail.${DOMINIO} -> 10.10.10.25" \
    bash -c "dig +short @${NS1} mail.${DOMINIO} A | grep -qx '10.10.10.25'"

probar "Registro TXT (política SPF estricta): v=spf1 mx -all" \
    bash -c "dig +short @${NS1} ${DOMINIO} TXT | grep -qi 'v=spf1 mx -all'"

probar "Registro CAA (autoridad certificadora): issue \"horizonte.internal\"" \
    bash -c "dig +short @${NS1} ${DOMINIO} CAA | grep -qi 'horizonte.internal'"

probar "Registro Inverso PTR: 10.10.10.20 -> www.${DOMINIO}." \
    bash -c "dig +short @${NS1} -x 10.10.10.20 | grep -qi 'www.${DOMINIO}.'"

probar "Registro Inverso PTR: 10.10.10.25 -> mail.${DOMINIO}." \
    bash -c "dig +short @${NS1} -x 10.10.10.25 | grep -qi 'mail.${DOMINIO}.'"

probar "Bandera de Autoridad (aa flag) activa en ns1" \
    bash -c "dig +norec @${NS1} www.${DOMINIO} | grep -q 'flags:.* aa'"

# ------------------------------------------------------------------------------
# FASE 2: Replicación y Secundario (ns2)
# ------------------------------------------------------------------------------
echo -e "\n${AMARILLO}--- FASE 2: Sincronización y Servidor Secundario (ns2) ---${RESET}"

probar "Respuesta autoritativa desde el Secundario (ns2 aa flag)" \
    bash -c "dig +norec @${NS2} www.${DOMINIO} | grep -q 'flags:.* aa'"

probar "Resolución en ns2 de CNAME encadenado hasta IP (portal -> 10.10.10.20)" \
    bash -c "dig +short @${NS2} portal.${DOMINIO} | grep -qx '10.10.10.20'"

probar "Resolución de Inversa PTR en el Secundario (ns2: 10.10.10.25)" \
    bash -c "dig +short @${NS2} -x 10.10.10.25 | grep -qi 'mail.${DOMINIO}.'"

SERIAL_NS1=$(dig +short @${NS1} ${DOMINIO} SOA | awk '{print $3}')
SERIAL_NS2=$(dig +short @${NS2} ${DOMINIO} SOA | awk '{print $3}')

probar "Consistencia de Número de Serie SOA (ns1=${SERIAL_NS1:-none} vs ns2=${SERIAL_NS2:-none})" \
    bash -c "[[ -n '${SERIAL_NS1}' && '${SERIAL_NS1}' == '${SERIAL_NS2}' ]]"

# ------------------------------------------------------------------------------
# FASE 3: Seguridad Perimetral y Control de Transferencia
# ------------------------------------------------------------------------------
echo -e "\n${AMARILLO}--- FASE 3: Seguridad Perimetral, TSIG y Recursión ---${RESET}"

probar "Transferencia de Zona (AXFR) SIN clave TSIG -> Rechazada (Transfer failed)" \
    bash -c "dig @${NS1} ${DOMINIO} AXFR | grep -qi 'Transfer failed'"

probar "Transferencia de Zona (AXFR) CON clave TSIG -> Exitosa y Autenticada" \
    bash -c "dig -k ${CLAVE_TSIG} @${NS1} ${DOMINIO} AXFR | grep -qi 'transferencia-horizonte.*NOERROR'"

probar "Rechazo de Recursión externa (ns1 responde REFUSED a dominios ajenos)" \
    bash -c "dig @${NS1} google.com A | grep -qi 'status: REFUSED'"

probar "Ofuscación de Versión de BIND (CH TXT version.bind -> 'no disponible')" \
    bash -c "[[ \"\$(dig +short @${NS1} CH TXT version.bind)\" == '\"no disponible\"' ]]"

# ------------------------------------------------------------------------------
# RESUMEN FINAL
# ------------------------------------------------------------------------------
echo -e "\n${AZUL}==================================================================${RESET}"
if [[ ${ok} -eq ${total} ]]; then
    echo -e "${VERDE}   RESULTADO FINAL: ${ok} de ${total} PRUEBAS SUPERADAS CON ÉXITO (100%)${RESET}"
    echo -e "${CYAN}   Estado: Infraestructura DNS lista para Defensa y Evaluación.${RESET}"
else
    echo -e "${ROJO}   RESULTADO FINAL: ${ok} de ${total} pruebas aprobadas. Revise los fallos.${RESET}"
fi
echo -e "${AZUL}==================================================================${RESET}"

[[ ${ok} -eq ${total} ]]
