# AX210 5GHz en Chile 🇨🇱

Parches para habilitar 5 GHz en tarjetas Intel AX210 en Chile (y cualquier país con LAR problemático).

## 📦 Contenido

### 1. `hostapd-lar/` - Hostapd con LAR + noscan patch
Parche para hostapd que fuerza un **scan WiFi antes de inicializar los canales**, lo que hace que el firmware Intel detecte el país desde redes 5 GHz cercanas y active el dominio regulatorio correcto vía LAR.

**Método recomendado** si hay redes 5 GHz cerca.

```bash
cd hostapd-lar
makepkg -si
```

Incluye:
- [hostapd-2.10-lar.patch](https://tildearrow.org/?p=post&month=7&year=2022&item=lar) de tildearrow (adaptado a 2.11)
- noscan patch (incluido en el mismo patch)
- FHS config patch (oficial de Arch)

### 2. `iwlwifi-lar-disable-zen7.1.2.patch` - Kernel patch
Parche para el driver `iwlmvm` que agrega el parámetro `lar_disable` para desactivar LAR por completo y forzar al kernel a controlar el dominio regulatorio.

**Método alternativo** si no hay redes 5 GHz cerca.

```bash
cp iwlwifi-lar-disable-zen7.1.2.patch al PKGBUILD de linux-zen
# Recompilar el kernel con el patch
```

## 🚀 Instalación automática

El script `install.sh` hace todo automáticamente:

```bash
# Clonar
git clone https://github.com/JDis03/ax210-5ghz-chile.git
cd ax210-5ghz-chile

# Ejecutar instalación (te pedirá SSID y contraseña)
./install.sh
```

**Qué hace:**
1. ✅ Compila e instala `hostapd-lar` (reemplaza al official)
2. ✅ Detecta tu interfaz WiFi automáticamente
3. ✅ Te pide SSID y contraseña
4. ✅ Crea `/etc/hostapd/hostapd.conf` con canal 149 (5 GHz)
5. ✅ Habilita y arranca el servicio systemd
6. ✅ Muestra verificación final

### Manual

```bash
cd hostapd-lar
makepkg -si
# luego configurar /etc/hostapd/hostapd.conf manualmente
sudo systemctl enable --now hostapd
```

## 🔧 Cómo funciona

### LAR patch (hostapd)
```
hostapd arranca
  → Hace un scan WiFi pasivo
  → Firmware Intel detecta país desde APs cercanos
  → LAR configura el dominio regulatorio (ej: CL)
  → hostapd obtiene canales 5 GHz
  → AP se inicia en canal 149 (5 GHz) ✅
```

### Kernel patch (iwlwifi)
```
modprobe iwlmvm lar_disable=1
  → iwl_mvm_is_lar_supported() retorna FALSE
  → NO se setea REGULATORY_WIPHY_SELF_MANAGED
  → Kernel controla regulatory (cfg80211)
  → Se respeta cfg80211.ieee80211_regdom=CL
  → Canales 5 GHz disponibles ✅
```

## ⚙️ Configuraciones recomendadas

### ⭐ Recomendada: 5 GHz 80 MHz (VHT80) + WiFi 6 con bridge
Configuración probada y funcionando en Chile con LAR activo. No requiere kernel patch.
`bridge=br0` permite que los clientes WiFi reciban IP del router directamente.
`noscan=1` evita el OBSS scan que colgaba el proceso en la AX210.

```conf
interface=wls17        # cambiar por tu interfaz
bridge=br0             # bridge de red existente (ver nota abajo)
driver=nl80211
ssid=DarkNet-5G
country_code=CL
wpa=2
wpa_passphrase=TuContraseña
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
auth_algs=1
macaddr_acl=0
ignore_broadcast_ssid=0
hw_mode=a
channel=149
noscan=1
ht_capab=[HT40+]
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=155
ieee80211n=1
ieee80211ac=1
ieee80211ax=1
wmm_enabled=1
ieee80211d=1
ctrl_interface=/var/run/hostapd
```

> **Nota bridge:** `br0` debe existir antes de que inicie hostapd.
> Crearlo con NetworkManager: `nmcli con add type bridge ifname br0 con-name br0`
> Agregar tu interfaz ethernet: `nmcli con add type ethernet ifname eth0 master br0`

### 🌟 2.4 GHz ULTRA (canal 13 + HT40 + Wi-Fi 6)
Configuración probada para máxima estabilidad y cobertura en 2.4 GHz.
Canal 13 (2472 MHz) es el más alto disponible en Chile.
HT40- da 40 MHz de ancho. Recomendada si 5 GHz no es estable.

```conf
interface=wls17
bridge=br0
driver=nl80211
ssid=DarkNet
country_code=CL
wpa=2
wpa_passphrase=DarkLab2024!
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
auth_algs=1
macaddr_acl=0
ignore_broadcast_ssid=0
hw_mode=g
channel=13
noscan=1
ht_capab=[HT40-][SHORT-GI-20][SHORT-GI-40][MAX-AMSDU-7935]
ieee80211n=1
ieee80211ax=1
wmm_enabled=1
ieee80211d=1
ctrl_interface=/var/run/hostapd
```

### Básica: 5 GHz 40 MHz + WiFi 6
Fallback si 80 MHz no funciona en tu firmware/región.

```conf
hw_mode=a
channel=149
noscan=1
ht_capab=[HT40+]
ieee80211n=1
ieee80211ac=1
ieee80211ax=1
```

### Avanzada: kernel patch + 160 MHz
Desactiva LAR por completo compilando el kernel con
`iwlwifi-lar-disable-zen7.1.2.patch`. Permite 160 MHz y canales DFS sin restricciones.

```conf
hw_mode=a
channel=36
ht_capab=[HT40+]
vht_oper_chwidth=2            # 160 MHz
vht_oper_centr_freq_seg0_idx=50   # centro para canal 36-64
ieee80211n=1
ieee80211ac=1
ieee80211ax=1
```

### WiFi 6E (6 GHz)
Requiere kernel patch + firmware compatible. Sin probar.

```conf
hw_mode=a
channel=1                     # canal 6GHz
ht_capab=[HT40+]
vht_oper_chwidth=1
vht_oper_centr_freq_seg0_idx=1
ieee80211n=1
ieee80211ac=1
ieee80211ax=1
```

## 📡 Canales 5 GHz

| Banda | Canales | Frecuencia | Ancho máx | DFS |
|-------|---------|-----------|-----------|-----|
| UNII-1 | 36-48 | 5180-5240 MHz | 80 MHz | ❌ |
| UNII-2 | 52-64 | 5260-5320 MHz | 80 MHz | ⚠️ |
| UNII-2e | 100-144 | 5500-5720 MHz | 160 MHz | ⚠️ |
| UNII-3 | 149-165 | 5735-5835 MHz | 80 MHz | ❌ |
| WiFi 6E | 1-233 | 5945-6425 MHz | 320 MHz | ❌ |

## ✅ Estado

- [x] Hostapd LAR patch compilado y probado en kernel 7.1.2-zen3-1-zen
- [x] 5 GHz funcionando en canal 149 con AX210
- [x] Dominio regulatorio CL detectado correctamente
- [x] **80 MHz (VHT80) con LAR activo** — funciona en UNII-3 (canal 149, centr_idx=155)
- [x] Bridge `br0` — clientes reciben IP del router directamente
- [ ] 160 MHz (requiere kernel patch)
- [ ] WiFi 6E (6 GHz)

## 📚 Referencias

- [Post original de tildearrow](https://tildearrow.org/?p=post&month=7&year=2022&item=lar)
- [Bugzilla kernel - LAR disable removal](https://bugzilla.kernel.org/show_bug.cgi?id=206469)
- [Intel community - LAR breaks 5GHz](https://community.intel.com/t5/Wireless/WIRELESS-AC-9260-regulatory-LAR-DRS-breaks-5ghz-functionality/m-p/711761)
- [Zen kernel](https://github.com/zen-kernel/zen-kernel)

## 📝 Licencia

GPL-2.0 (igual que el kernel Linux y hostapd)

---

Hecho con ❤️ para la comunidad Arch Linux en Chile y países con LAR problemático.
