@echo off
where node >nul 2>nul
if errorlevel 1 (
  echo Для запуска игры требуется Node.js.
  echo Установите Node.js LTS или откройте index.html для одиночной игры.
  pause
  exit /b 1
)
start "Стальной рубеж" cmd /k "cd /d ""%~dp0"" && node server.cjs"
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:8765"
