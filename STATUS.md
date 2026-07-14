# AX210 5GHz Chile - Estado del Proyecto

> Última actualización: 2026-07-14

## 🎯 Objetivo
Habilitar AP en 5 GHz con tarjeta Intel AX210 en Chile (país CL).

## 📦 Repo
https://github.com/JDis03/ax210-5ghz-chile

---

## ✅ Logrado

### 1. Hostapd LAR patch (en uso actualmente)
- **Binary:** `/usr/bin/hostapd` (hostapd-lar 2.11)
- **Paquete:** `hostapd-lar-2.11-1-x86_64.pkg.tar.zst`
- **Service:** `hostapd.service` (enabled)
- **Config:** `/etc/hostapd/hostapd.conf`
- **Estado:** ✅ Funcionando
- **AP:** DarkNet (2.4 GHz) canal 13, HT40- (40 MHz), Wi-Fi 6
- **AP (prev):** DarkNet-5G, canal 149, **80 MHz (VHT80)**, WiFi 6
- **Bridge:** `bridge=br0` en hostapd.conf (clientes reciben IP del router)
- **Systemd:** override.conf con `After=NetworkManager-wait-online.service`

### 2. Kernel patch (alternativa)
- **Patch:** `iwlwifi-lar-disable-zen7.1.2.patch`
- **Módulo original restaurado:** `/lib/modules/7.1.2-zen3-1-zen/kernel/.../iwlmvm.ko.zst`
- **Backup del módulo original:** existe en `.zst.backup`
- **Estado:** ⏸️ Pendiente de compilar/integrar

### 3. Repo GitHub
- **URL:** https://github.com/JDis03/ax210-5ghz-chile
- **Contenido:**
  - `hostapd-lar/` - PKGBUILD + patches para hostapd-lar
  - `iwlwifi-lar-disable-zen7.1.2.patch` - Kernel patch
  - `install.sh` - Script de instalación automática
  - `README.md` - Documentación principal

---

## 📋 Pendiente

### 🟢 Resuelto hoy (2026-07-10)
- **80 MHz funciona con LAR activo** — no se necesita kernel patch para VHT80 en canal 149
- **bridge=br0** en hostapd.conf → clientes reciben IP del router transparentemente
- **Systemd ordering** — `After=NetworkManager-wait-online.service` garantiza que br0 exista antes de hostapd
- **Causa del AP invisible**: `ieee80211h=1` sin `ieee80211d=1` + config HE incompleta causaba beacons inválidos. Simplificar la config resolvió el problema.
- **2.4 GHz ULTRA**: canal 13 (2472 MHz), HT40- (40 MHz), Wi-Fi 6, Short GI, MAX-AMSDU, `noscan=1` — config probada y estable.

### 🔴 Alta prioridad

#### 1. Compilar kernel con patch (para 160 MHz)
```bash
cd /home/dark/Project/ax210-5ghz-patch
# Clonar PKGBUILD de linux-zen
git clone https://gitlab.archlinux.org/archlinux/packaging/packages/linux-zen.git
cd linux-zen
# Copiar patch
cp ../iwlwifi-lar-disable-zen7.1.2.patch .
# Editar PKGBUILD:
#   - Agregar a source=() el patch
#   - Agregar a prepare() patch -Np1 -i ../iwlwifi-lar-disable-zen7.1.2.patch
# Compilar
makepkg -si
# Configurar
echo "options iwlmvm lar_disable=1" | sudo tee /etc/modprobe.d/iwlwifi-lar-disable.conf
sudo reboot
```

#### 2. Probar 80 MHz con kernel patch
Después de compilar, editar `/etc/hostapd/hostapd.conf`:
```
# Cambiar de 40 MHz a 80 MHz
channel=149
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=155
```

#### 3. Probar 160 MHz (requiere kernel patch + DFS)
```
channel=36
vht_oper_chwidth=2
vht_oper_centr_freq_seg0_idx=50
```

### 🟡 Media prioridad

#### 4. Probar WiFi 6E (6 GHz)
- Verificar si firmware del AX210 lo soporta
- Agregar canales 6 GHz a hostapd.conf

#### 5. Probar en otros kernels
- Probar con kernel vanilla (no zen)
- Probar con otras versiones

#### 6. Subir a AUR
- El PKGBUILD ya está listo (`hostapd-lar/`)
- Crear cuenta en AUR y subir como `hostapd-lar`
- La gente podría instalarlo con: `yay -S hostapd-lar`

### 🟢 Baja prioridad

#### 7. Mejorar install.sh
- Detectar bridge br0 automáticamente
- Preguntar por ancho de canal
- Opción `--unattended` para scripting

#### 8. Probar con múltiples SSID
- Tener DarkNet (2.4 GHz) + DarkNet-5G (5 GHz) simultáneamente

---

## 🔧 Comandos útiles

### Ver estado del AP
```bash
iw dev wls17 info
sudo systemctl status hostapd
sudo journalctl -u hostapd -f
```

### Probar en foreground (debug)
```bash
sudo systemctl stop hostapd
sudo hostapd -dd /etc/hostapd/hostapd.conf
```

### Cambiar config y reiniciar
```bash
sudo vim /etc/hostapd/hostapd.conf
sudo systemctl restart hostapd
```

### Rollback
```bash
# Si el kernel patch no funciona
sudo cp /lib/modules/$(uname -r)/kernel/.../iwlmvm.ko.zst.backup \
        /lib/modules/$(uname -r)/kernel/.../iwlmvm.ko.zst
sudo depmod -a
# Desinstalar hostapd-lar y reinstalar hostapd oficial
sudo pacman -S hostapd
```

---

## 📁 Estructura del repo
```
ax210-5ghz-chile/
├── README.md           ← Documentación principal
├── STATUS.md           ← Este archivo
├── install.sh          ← Instalación automática
├── .gitignore
├── iwlwifi-lar-disable-zen7.1.2.patch  ← Kernel patch
└── hostapd-lar/
    ├── PKGBUILD        ← Paquete Arch Linux
    ├── .SRCINFO        ← Para AUR
    ├── config          ← Config de compilación (AC+AX+BE)
    ├── hostapd-2.11-lar-noscan.patch   ← LAR + noscan patch
    ├── hostapd-2.11-fhs-config.patch   ← FHS patch oficial
    ├── hostapd.service                  ← Systemd service
    ├── hostapd@.service                 ← Systemd template
    └── hostapd-lar.tmpfiles
```

## 💡 Notas técnicas

### LAR patch - Cómo funciona
```
hostapd arranca
  → COUNTRY_UPDATE (aplica country_code=CL)
  → HT_SCAN (scan pasivo de redes cercanas)
  → Firmware Intel detecta país desde APs cercanos
  → LAR configura dominio regulatorio
  → Canales 5 GHz aparecen
  → AP-ENABLED en canal 149 ✅
```

### Kernel patch - Cómo funciona
```
iwl_mvm_is_lar_supported():
  if (iwlmvm_mod_params_lar_disable)
    return false;  ← fuerza al kernel a controlar regulatory
  // resto del código original
```

### Por qué 40 MHz y no 80 MHz con LAR
- El firmware del AX210 con LAR activo limita el ancho de canal a 40 MHz en UNII-3
- Para 80/160 MHz se requiere desactivar LAR (kernel patch)
- En la banda UNII-1 (canales 36-48) podría funcionar 80 MHz incluso con LAR,
  pero requiere passive scan primero (el firmware bloquea IR hasta detectar país)

---

*Documentado para retomar después. Creado: 2026-07-07*
