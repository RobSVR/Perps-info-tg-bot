# Инструкция по деплою бота на сервер 24/7

## 1. Выбор сервера

Рекомендуемые варианты:
- **DigitalOcean** (от $6/мес) - Ubuntu
- **Hetzner** (от €4/мес) - Ubuntu
- **Linode** (от $5/мес) - Ubuntu
- **AWS/GCP** - если нужен масштаб

Минимальные требования:
- 1 CPU core
- 1 GB RAM
- 25 GB SSD
- Ubuntu 20.04 или 22.04 LTS

## 2. Подготовка сервера

### Подключение к серверу:
```bash
ssh root@YOUR_SERVER_IP
```

### Обновление системы:
```bash
apt update && apt upgrade -y
```

### Установка Python и pip:
```bash
apt install python3 python3-pip git -y
python3 --version
```

## 3. Деплой бота на сервер

### Клонирование проекта (если используете Git):
```bash
cd /opt
git clone YOUR_REPO_URL Perps-info-tg-bot
cd Perps-info-tg-bot
```

### Или загрузка файлов через SFTP:
```bash
# Используйте WinSCP, FileZilla или SCP
scp -r /путь/к/проекту root@YOUR_SERVER_IP:/opt/Perps-info-tg-bot
```

### Установка зависимостей:
```bash
cd /opt/Perps-info-tg-bot
pip3 install -r requirements.txt
```

## 4. Настройка конфигурации

### Создание файла .env:
```bash
nano /opt/Perps-info-tg-bot/.env
```

Добавьте:
```
BOT_TOKEN=your_bot_token_here
CHANNEL_ID=@your_channel
CHANNEL_ID_NUMERIC=-1001234567890
```

## 5. Настройка автозапуска через systemd

### Создание сервисного файла:
```bash
nano /etc/systemd/system/perps-bot.service
```

Вставьте конфигурацию:
```ini
[Unit]
Description=Perps Info Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/Perps-info-tg-bot
Environment="PATH=/usr/bin"
ExecStart=/usr/bin/python3 /opt/Perps-info-tg-bot/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Активация и запуск сервиса:
```bash
# Перезагрузка systemd
systemctl daemon-reload

# Включение автозапуска
systemctl enable perps-bot.service

# Запуск бота
systemctl start perps-bot.service

# Проверка статуса
systemctl status perps-bot.service
```

### Управление ботом:
```bash
# Запуск
systemctl start perps-bot

# Остановка
systemctl stop perps-bot

# Перезапуск
systemctl restart perps-bot

# Статус
systemctl status perps-bot

# Просмотр логов
journalctl -u perps-bot -f
```

## 6. Настройка логов

### Создание директории для логов:
```bash
mkdir -p /var/log/perps-bot
chmod 755 /var/log/perps-bot
```

### Настройка ротации логов:
```bash
nano /etc/logrotate.d/perps-bot
```

Добавьте:
```
/var/log/perps-bot/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0644 root root
}
```

## 7. Дополнительные настройки

### Firewall (ufw):
```bash
ufw allow 22/tcp
ufw enable
```

### Мониторинг:
```bash
# Установка htop
apt install htop -y

# Просмотр процесса бота
ps aux | grep bot.py

# Использование памяти
free -h

# Диск
df -h
```

## 8. Обновление бота

### Если используете Git:
```bash
cd /opt/Perps-info-tg-bot
git pull
systemctl restart perps-bot
```

### Если обновляете файлы вручную:
```bash
# Остановка бота
systemctl stop perps-bot

# Обновление файлов (через SFTP или копирование)
# ...

# Запуск бота
systemctl start perps-bot
```

## 9. Резервное копирование

### Создание скрипта бэкапа:
```bash
nano /opt/backup-bot.sh
```

Добавьте:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf /opt/backups/perps-bot-$DATE.tar.gz /opt/Perps-info-tg-bot
```

### Активация регулярных бэкапов:
```bash
mkdir -p /opt/backups
chmod +x /opt/backup-bot.sh

# Добавление в cron
crontab -e
# Добавьте: 0 3 * * * /opt/backup-bot.sh
```

## 10. Альтернативный вариант: Docker (опционально)

### Создание Dockerfile:
```bash
nano Dockerfile
```

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "bot.py"]
```

### Запуск через Docker:
```bash
docker build -t perps-bot .
docker run -d --name perps-bot --restart unless-stopped perps-bot
```

## Полезные команды

```bash
# Последние логи
tail -f /var/log/syslog | grep perps

# Просмотр всех запущенных сервисов
systemctl list-units --type=service

# Проверка сетевых соединений
netstat -tulpn

# Перезагрузка сервера (бот запустится автоматически)
reboot
```

## Решение проблем

### Бот не запускается:
```bash
systemctl status perps-bot
journalctl -u perps-bot -n 50
```

### Проверка токена:
```bash
cd /opt/Perps-info-tg-bot
cat .env
```

### Тестовый запуск:
```bash
cd /opt/Perps-info-tg-bot
python3 bot.py
```

## Безопасность

1. Используйте сильные пароли
2. Настройте SSH ключи вместо паролей
3. Отключите root логин в SSH
4. Используйте fail2ban для защиты от брутфорса
5. Регулярно обновляйте систему

```bash
# Установка fail2ban
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
```

