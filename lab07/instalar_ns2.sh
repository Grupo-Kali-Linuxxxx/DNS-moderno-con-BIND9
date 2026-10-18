#!/usr/bin/env bash
# instalar_ns2.sh — Configura ns2 como SECUNDARIO de horizonte.internal. Ejecutar EN ns2:  bash /lab/lab07/instalar_ns2.sh
set -euo pipefail
cd "$(dirname "$0")"
[[ $EUID -eq 0 ]] || { echo "Ejecuta como root (o con sudo)"; exit 1; }
[[ -s compartido/transferencia.key ]] || { echo "Falta compartido/transferencia.key: ejecuta primero instalar_ns1.sh en ns1"; exit 1; }

# 1. Clave TSIG compartida (leída de compartido/, creada por ns1)
install -o root -g bind -m 640 compartido/transferencia.key /etc/bind/transferencia.key

# 2. Configuración del secundario (no tiene archivos de zona propios: los pide a ns1 por AXFR)
install -o root -g bind -m 644 ns2/named.conf.options ns2/named.conf.local /etc/bind/

# 3. Validar y aplicar
named-checkconf
systemctl enable named >/dev/null 2>&1
if systemctl is-active -q named; then rndc reload; else systemctl start named; fi
sleep 2

# 4. Verificar que copió la zona
rndc zonestatus horizonte.internal | grep -E 'serial|type' || true
echo "ns2 listo: dig @10.10.10.3 www.horizonte.internal"
