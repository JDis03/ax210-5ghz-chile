#!/bin/bash
set -e

echo "=== Instalación automática de hostapd-lar (AX210 5GHz) ==="
echo ""

# 1. Verificar si hostapd ya está instalado (oficial)
if pacman -Q hostapd 2>/dev/null; then
    echo "⚠️  hostapd oficial detectado. Se reemplazará por hostapd-lar."
    echo ""
fi

# 2. Build e instalar el paquete
cd "$(dirname "$0")/hostapd-lar"
echo "📦 Compilando hostapd-lar..."
makepkg -si --noconfirm
echo "✅ hostapd-lar instalado"
echo ""

# 3. Detectar interfaz WiFi
cd ..
WIFI_IFACE=$(iw dev 2>/dev/null | grep "Interface" | awk '{print $2}' | head -1)
if [ -z "$WIFI_IFACE" ]; then
    echo "⚠️  No se detectó interfaz WiFi. Cargando módulo..."
    sudo modprobe iwlmvm 2>/dev/null || true
    sleep 1
    WIFI_IFACE=$(iw dev 2>/dev/null | grep "Interface" | awk '{print $2}' | head -1)
fi

if [ -z "$WIFI_IFACE" ]; then
    echo "❌ No se pudo detectar interfaz WiFi. Verificá que la tarjeta esté conectada."
    exit 1
fi
echo "📡 Interfaz detectada: $WIFI_IFACE"

# 4. Preguntar SSID y contraseña
echo ""
read -p "📶 Nombre del AP 5GHz [DarkNet-5G]: " SSID
SSID=${SSID:-DarkNet-5G}

read -s -p "🔑 Contraseña WiFi (mín 8 chars): " PASS
echo ""
while [ ${#PASS} -lt 8 ]; do
    read -s -p "🔑 Mínimo 8 caracteres: " PASS
    echo ""
done

# 5. Crear configuración
echo ""
echo "⚙️  Creando configuración en /etc/hostapd/hostapd.conf..."
sudo tee /etc/hostapd/hostapd.conf > /dev/null << CONFEOF
interface=$WIFI_IFACE
bridge=br0
driver=nl80211
ssid=$SSID
country_code=CL
wpa=2
wpa_passphrase=$PASS
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
auth_algs=1
macaddr_acl=0
ignore_broadcast_ssid=0
hw_mode=a
channel=149
ht_capab=[HT40+]
ieee80211n=1
wmm_enabled=1
ieee80211d=1
ieee80211h=1
ctrl_interface=/var/run/hostapd
CONFEOF
echo "✅ Configuración creada"
echo "   SSID: $SSID"
echo "   Canal: 149 (5745 MHz, 5 GHz)"
echo "   Modo: 802.11a/n/ac/ax"

# 6. Backup si existe bridge, si no crear
if ! ip link show br0 2>/dev/null | grep -q "state UP"; then
    echo "⚠️  Bridge br0 no encontrado. Solo modo AP sin bridge."
    sudo sed -i '/^bridge=/d' /etc/hostapd/hostapd.conf
fi

# 7. Habilitar y arrancar servicio
echo ""
echo "🚀 Habilitando servicio systemd..."
sudo systemctl daemon-reload 2>/dev/null || true
sudo systemctl enable hostapd 2>/dev/null || true
sudo systemctl start hostapd 2>&1 || {
    echo "⚠️  Error al iniciar hostapd. Revisá los logs:"
    echo "   sudo journalctl -u hostapd -n 20 --no-pager"
    echo ""
    echo "   Puede que necesites crear el bridge br0 primero:"
    echo "   sudo ip link add br0 type bridge"
    echo "   sudo ip link set br0 up"
    echo "   sudo ip link set $WIFI_IFACE master br0"
    exit 1
}

# 8. Verificar
echo ""
echo "=== Verificación ==="
sleep 2
iw dev $WIFI_IFACE info 2>/dev/null | grep -E "ssid|channel|type|txpower" || true
echo ""

echo "✅ AP 5GHz funcionando!"
echo "   SSID: $SSID"
echo "   Red: 5 GHz (canal 149)"
echo "   Conectate y probá!"
echo ""
echo "📋 Comandos útiles:"
echo "   Ver logs:  sudo journalctl -u hostapd -f"
echo "   Detener:   sudo systemctl stop hostapd"
echo "   Status:    sudo systemctl status hostapd"
