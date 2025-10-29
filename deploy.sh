#!/bin/bash
# Скрипт для автоматического деплоя бота на сервер

echo "🚀 Deploy скрипт для Perps Info Bot"
echo "================================"
echo ""

# Проверка аргументов
if [ -z "$1" ]; then
    echo "Использование: ./deploy.sh USER@SERVER_IP"
    echo "Пример: ./deploy.sh root@123.45.67.89"
    exit 1
fi

SERVER=$1
REMOTE_DIR="/opt/Perps-info-tg-bot"

echo "📤 Загрузка файлов на сервер $SERVER..."
echo ""

# Создание директории на сервере
ssh $SERVER "mkdir -p $REMOTE_DIR"

# Загрузка файлов (исключая ненужные)
rsync -avz --exclude='.git' \
          --exclude='.env' \
          --exclude='__pycache__' \
          --exclude='*.pyc' \
          . $SERVER:$REMOTE_DIR/

echo ""
echo "✅ Файлы загружены!"
echo ""

# Проверка .env файла
echo "🔍 Проверка файла .env..."
if ssh $SERVER "[ ! -f $REMOTE_DIR/.env ]"; then
    echo "⚠️  Файл .env не найден!"
    echo "Создайте файл .env на сервере с токеном бота"
    echo "Скопируйте config_example.py -> .env и заполните"
else
    echo "✅ Файл .env существует"
fi

# Установка зависимостей
echo ""
echo "📦 Установка Python зависимостей..."
ssh $SERVER "cd $REMOTE_DIR && pip3 install -r requirements.txt"

# Установка systemd сервиса
echo ""
echo "⚙️  Установка systemd сервиса..."
scp perps-bot.service $SERVER:/tmp/
ssh $SERVER "sudo mv /tmp/perps-bot.service /etc/systemd/system/"
ssh $SERVER "sudo systemctl daemon-reload"
ssh $SERVER "sudo systemctl enable perps-bot.service"

echo ""
echo "🤖 Бот будет запущен автоматически при загрузке сервера"
echo ""
echo "📋 Полезные команды для управления ботом:"
echo "  Запуск:     ssh $SERVER 'sudo systemctl start perps-bot'"
echo "  Остановка:  ssh $SERVER 'sudo systemctl stop perps-bot'"
echo "  Перезапуск: ssh $SERVER 'sudo systemctl restart perps-bot'"
echo "  Статус:     ssh $SERVER 'sudo systemctl status perps-bot'"
echo "  Логи:       ssh $SERVER 'sudo journalctl -u perps-bot -f'"
echo ""
echo "🎉 Деployment завершен!"
echo "Не забудьте настроить файл .env на сервере!"

