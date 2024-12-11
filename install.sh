#!/bin/bash

# Configuración de la aplicación
PORT=6482
SERVICE_NAME="TimerControl"
APP_AUTHOR="Marcelo Mendoza"
APP_VERSION="1.0.0"
APP_DESCRIPTION="Control de tiempo para presentaciones en vivo"
APP_DATE="11 de Septiembre de 2024"
APP_COPYRIGHT="(c) 2024 Marcelo Mendoza"
APP_GITHUB="@enfermero-dev"
TARGET_DIR="/opt/$SERVICE_NAME"

# Variables internas
NODE_PATH=$(which node)
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)
SOURCE_DIR="./"

show_help() {
    echo "Uso: $0 {--install|-i|--uninstall|-u|--update|-U}"
    exit 1
}

check_permissions() {
    if ! sudo -l &>/dev/null; then
        echo "El usuario actual no tiene privilegios suficientes."
        echo "Por favor, ejecuta como un usuario con privilegios de sudo."
        exit 1
    fi
}

configure() {
    echo "$SERVICE_NAME CONFIGURACIÓN"
    read -p "Introduce el número de puerto [por defecto: $PORT]: " PORT
    PORT=${PORT:-$PORT}
}

case "$1" in
    --install | -i)
        check_permissions
        echo "Instalando $SERVICE_NAME..."
        ;;
    --uninstall | -u)
        check_permissions
        echo "Desinstalando $SERVICE_NAME..."
        ;;
    --help | -h)
        show_help
        ;;
    *)
        show_help
        ;;
esac

install(){
    echo "Comprobando si el servicio ya está instalado..."
    if [ -d "$TARGET_DIR" ]; then
        echo "$SERVICE_NAME ya está instalado."
        echo "¿Deseas reinstalarlo? [s/n]"
        read -r REINSTALL
        if [[ "$REINSTALL" != "s" ]]; then
            echo "Instalación cancelada."
            exit 1
        fi
        echo "Desinstalando $SERVICE_NAME..."
        sudo rm -rf "$TARGET_DIR"
    fi
    echo "Instalando $SERVICE_NAME..."
    sudo mkdir -p "$TARGET_DIR"
    sudo cp -r "$SOURCE_DIR" "$TARGET_DIR"
    sudo chown -R "$CURRENT_USER:$CURRENT_GROUP" "$TARGET_DIR"
    sudo chmod -R 755 "$TARGET_DIR"
    echo "$SERVICE_NAME instalado en $TARGET_DIR"
    echo "Instalando dependencias..."
    cd "$TARGET_DIR"
    if ! npm install; then
        echo "Error al instalar las dependencias."
        exit 1
    fi
    echo "Creando servicio..."
    echo "[Unit]
Description=$SERVICE_NAME
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_GROUP
WorkingDirectory=$TARGET_DIR
ExecStart=$NODE_PATH $TARGET_DIR/index.js
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl start "$SERVICE_NAME"
    echo "Servicio $SERVICE_NAME instalado y activado."
}

uninstall() {
    echo "Desinstalando $SERVICE_NAME..."
    sudo systemctl stop "$SERVICE_NAME"
    sudo systemctl disable "$SERVICE_NAME"
    sudo rm "/etc/systemd/system/$SERVICE_NAME.service"
    sudo rm -rf "$TARGET_DIR"
    sudo systemctl daemon-reload
    echo "Servicio $SERVICE_NAME desinstalado."
}

update() {
    echo "Actualizando $SERVICE_NAME..."
    if [ -f "$TARGET_DIR/.env" ]; then
        cp "$TARGET_DIR/.env" "$PWD/.env.bak"
    fi
    cp -r "$SOURCE_DIR"/* "$TARGET_DIR/"
    cd "$TARGET_DIR" || exit 1
    sudo chown -R "$CURRENT_USER:$CURRENT_GROUP" .
    if [ -f "$PWD/.env.bak" ]; then
        cp "$PWD/.env.bak" "$TARGET_DIR/.env"
        rm "$PWD/.env.bak"
    fi
    if ! npm install; then
        echo "Error al instalar las dependencias."
        exit 1
    fi
    sudo systemctl restart "$SERVICE_NAME"
    echo "Servicio $SERVICE_NAME actualizado."
}

show_help() {
    echo "Uso: $0 {--install|-i|--uninstall|-u|--update|-U}"
    exit 1
}

case "$1" in
    --install | -i)
        install
        ;;
    --uninstall | -u)
        uninstall
        ;;
    --update | -U)  # Cambié la opción corta para update a -U para evitar duplicados
        update
        ;;
    *)
        show_help
        ;;
esac

exit 0