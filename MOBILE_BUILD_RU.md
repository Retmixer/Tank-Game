# Мобильная версия

Игра получила адаптивный интерфейс, сенсорный обзор и экранные кнопки движения, оптики и выстрела. На Android её можно установить как полноэкранное PWA из Chrome: запустите сервер игры, откройте адрес с телефона и выберите «Добавить на главный экран».

Для APK используйте Capacitor после установки Android Studio и Android SDK:

```powershell
npm install
npx cap add android
npx cap copy
npx cap open android
```

В Android Studio выберите `Build > Build APK(s)`. В текущей рабочей среде Android SDK и Gradle отсутствуют, поэтому бинарный APK здесь не генерируется; исходники игры и мобильная PWA-обвязка готовы для сборки на машине с Android Studio.
