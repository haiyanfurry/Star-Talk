#!/bin/sh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Star-Talk / 星语 — KDE Plasma 6 Desktop Configuration            ║
# ║  Applied after pkgsrc install of Plasma 6 packages                 ║
# ╚══════════════════════════════════════════════════════════════════════╝

TARGET_USER="${1:-startalk}"
TARGET_HOME="${2:-/home/${TARGET_USER}}"
WALLPAPER_SRC="/usr/local/share/star-talk/wallpapers/star-talk.png"
KDE_CONFIG="${TARGET_HOME}/.config"

echo "==> Star-Talk KDE Plasma 6 Configuration"
echo "    User: ${TARGET_USER}"

# ── Wallpaper ──────────────────────────────────────────────────────────
mkdir -p "${TARGET_HOME}/.local/share/wallpapers"
if [ -f "$WALLPAPER_SRC" ]; then
    cp "$WALLPAPER_SRC" "${TARGET_HOME}/.local/share/wallpapers/star-talk.png"
    echo "    Wallpaper: installed"
fi

# ── Plasma 6 Shell Config ──────────────────────────────────────────────
mkdir -p "$KDE_CONFIG"

# plasmashellrc
cat > "${KDE_CONFIG}/plasmashellrc" << 'PLASMA6'
[Theme]
name=default

[Desktop View]
wallpaper=/home/startalk/.local/share/wallpapers/star-talk.png

[Panels]
[Panels][1]
alignment=center
height=46
location=bottom
floating=1

[Panels][1][Widgets]
widgets=org.kde.plasma.kickoff,org.kde.plasma.pager,org.kde.plasma.taskmanager,org.kde.plasma.systemtray,org.kde.plasma.digitalclock
PLASMA6

# kdeglobals
cat > "${KDE_CONFIG}/kdeglobals" << 'KDEGLOB6'
[General]
ColorScheme=BreezeLight
widgetStyle=Breeze

[KDE]
LookAndFeelPackage=org.kde.breeze.desktop

[Locale]
Country=CN
Language=zh_CN:en_US

[Icons]
Theme=breeze

[Fonts]
General=Noto Sans,10,-1,5,50,0,0,0,0,0,Regular
KDEGLOB6

# kwinrc (Plasma 6 — Wayland preferred, X11 fallback)
cat > "${KDE_CONFIG}/kwinrc" << 'KWIN6'
[Compositing]
OpenGLIsUnsafe=false
Backend=OpenGL
Enabled=true

[Desktops]
Id_1=Desktop
Name_1=Desktop
Number=1
Rows=1

[Wayland]
VirtualKeyboardEnabled=false

[Xwayland]
Enabled=true
KWIN6

# ── Konsole Config ─────────────────────────────────────────────────────
mkdir -p "$KDE_CONFIG"
cat > "${KDE_CONFIG}/konsolerc" << 'KONSOLE6'
[Desktop Entry]
DefaultProfile=Star-Talk.profile

[KonsoleWindow]
RememberWindowSize=false

[Profile Star-Talk]
ColorScheme=Breeze
Command=/bin/sh
Font=Noto Sans Mono,12,-1,5,50,0,0,0,0,0,Regular
HistoryMode=2
HistorySize=10000
LocalTabTitleFormat=%w : Star-Talk — Konsole
Name=Star-Talk
KONSOLE6

# ── Default Applications ───────────────────────────────────────────────
cat > "${KDE_CONFIG}/mimeapps.list" << 'MIME'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
inode/directory=org.kde.dolphin.desktop
text/plain=org.kde.kate.desktop
MIME

# ── Input Method Environment ───────────────────────────────────────────
mkdir -p "${TARGET_HOME}/.config/environment.d"
cat > "${TARGET_HOME}/.config/environment.d/input.conf" << 'INPUTENV'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUTENV

echo "==> KDE Plasma 6 configuration complete."
