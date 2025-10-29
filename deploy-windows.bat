@echo off
echo ================================================
echo  Deploy скрипт для Perps Info Bot (Windows)
echo ================================================
echo.

if "%1"=="" (
    echo Использование: deploy-windows.bat ваш_сервер_ip
    echo Пример: deploy-windows.bat 123.45.67.89
    exit /b 1
)

set SERVER=%1
set USER=root
set REMOTE_DIR=/opt/Perps-info-tg-bot

echo Подключаемся к серверу %SERVER%...
echo.

REM Создание директории на сервере
ssh %USER%@%SERVER% "mkdir -p %REMOTE_DIR%"

echo.
echo Загрузка файлов на сервер...
echo.

REM Загрузка файлов через scp (для Windows)
scp -r bot.py %USER%@%SERVER%:%REMOTE_DIR%/
scp -r config.py %USER%@%SERVER%:%REMOTE_DIR%/
scp -r requirements.txt %USER%@%SERVER%:%REMOTE_DIR%/
scp -r config_example.py %USER%@%SERVER%:%REMOTE_DIR%/
scp -r README.md %USER%@%SERVER%:%REMOTE_DIR%/ 2>nul

echo.
echo ================================================
echo  Файлы загружены!
echo ================================================
echo.
echo Следующие шаги:
echo 1. SSH на сервер: ssh root@%SERVER%
echo 2. Создайте файл .env: nano %REMOTE_DIR%/.env
echo 3. Добавьте: BOT_TOKEN=ваш_токен
echo 4. Установите зависимости: cd %REMOTE_DIR% ^&^& pip3 install -r requirements.txt
echo 5. Установите сервис: cp %REMOTE_DIR%/perps-bot.service /etc/systemd/system/
echo 6. Активируйте: systemctl daemon-reload ^&^& systemctl enable perps-bot ^&^& systemctl start perps-bot
echo.
pause

