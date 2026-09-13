# Мобильная версия

Игра получила адаптивный интерфейс, сенсорный обзор и экранные кнопки движения, оптики и выстрела. На Android её можно установить как полноэкранное PWA из Chrome: запустите сервер игры, откройте адрес с телефона и выберите «Добавить на главный экран».

Для APK используется Capacitor 6 и Android SDK. После установки зависимостей:

```powershell
npm install
npx cap add android
npx cap sync android
cd android
./gradlew.bat assembleDebug
```

Готовый debug-файл появится в `android/app/build/outputs/apk/debug/app-debug.apk`. Для Windows нужен JDK 17 и Android SDK Platform 35 (Build Tools 34+). Тестовый APK из текущей сборки сохранён в корне репозитория как `Steel-Frontier-debug.apk`.
