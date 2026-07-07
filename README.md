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

## 🚀 Instalación rápida (hostapd)

```bash
# 1. Instalar dependencias
sudo pacman -S --needed git base-devel

# 2. Clonar y compilar
git clone https://github.com/TU_USUARIO/ax210-5ghz-chile.git
cd ax210-5ghz-chile/hostapd-lar
makepkg -si

# 3. Configurar hostapd para 5 GHz
sudo tee /etc/hostapd/hostapd.conf << 'EOF'
interface=wls17
bridge=br0
driver=nl80211
ssid=DarkNet-5G
country_code=CL
wpa=2
wpa_passphrase=DarkLab2024!
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
EOF

# 4. Iniciar hostapd
sudo systemctl start hostapd
sudo systemctl enable hostapd
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

## 📡 Canales 5 GHz verificados

| Canal | Frecuencia | Ancho | Notas |
|-------|-----------|-------|-------|
| 36-48 | 5180-5240 MHz | 80 MHz | Sin DFS |
| 52-64 | 5260-5320 MHz | 80 MHz | DFS |
| 149-165 | 5735-5835 MHz | 80 MHz | Sin DFS |
| 1-233 | 5945-6425 MHz | 320 MHz | WiFi 6E |

## ✅ Estado

- [x] Hostapd LAR patch compilado y probado en kernel 7.1.2-zen3-1-zen
- [x] 5 GHz funcionando en canal 149 con AX210
- [x] Dominio regulatorio CL detectado correctamente
- [ ] Probar con otros kernels/versiones
- [ ] Probar WiFi 6E (6 GHz)

## 📚 Referencias

- [Post original de tildearrow](https://tildearrow.org/?p=post&month=7&year=2022&item=lar)
- [Bugzilla kernel - LAR disable removal](https://bugzilla.kernel.org/show_bug.cgi?id=206469)
- [Intel community - LAR breaks 5GHz](https://community.intel.com/t5/Wireless/WIRELESS-AC-9260-regulatory-LAR-DRS-breaks-5ghz-functionality/m-p/711761)
- [Zen kernel](https://github.com/zen-kernel/zen-kernel)

## 📝 Licencia

GPL-2.0 (igual que el kernel Linux y hostapd)

---

Hecho con ❤️ para la comunidad Arch Linux en Chile y países con LAR problemático.
