BLEP MAP — iOS / AltStore

ЭТО НЕ ГОТОВЫЙ IPA:
В архиве находится полноценный Xcode-проект и автоматическая сборка IPA.
Сам .ipa обязан быть скомпилирован Apple Xcode/iOS SDK на macOS.
После сборки AltStore переподпишет unsigned IPA твоим Apple ID.

ЧТО ЕСТЬ В IOS-КЛИЕНТЕ:
- отдельное приложение BLEP MAP;
- WKWebView вместо Safari;
- нативная геолокация через CoreLocation;
- navigator.geolocation внутри BLEP MAP заменяется native bridge;
- watchPosition работает для live-карты пока приложение открыто;
- haptic/vibration для Buzz;
- разрешения Location / Local Network / Photos / Camera / Microphone;
- поддержка HTTP-сервера в локальной сети;
- можно позже поставить HTTPS/VPS;
- адрес BLEP MAP сервера меняется прямо в приложении.

КАК ПОДКЛЮЧИТЬ К ТВОЕМУ ПК:
1. На ПК запусти BLEP MAP server.
2. Открой BLEP_MAP_ADDRESS.txt.
3. Там будет адрес вида:
   http://192.168.1.50:3199
4. iPhone должен быть в той же Wi-Fi сети.
5. Первый раз в iOS-приложении введи этот адрес.
6. Разреши Local Network и Location.

КАК ПОЛУЧИТЬ IPA НА MAC:
1. Открой BLEPMap.xcodeproj в Xcode
   ИЛИ запусти BUILD_IPA_ON_MAC.command.
2. Получишь BLEP_MAP_ALTSTORE.ipa.
3. AirDrop/Files -> iPhone -> AltStore -> My Apps -> + -> выбери IPA.

КАК ПОЛУЧИТЬ IPA БЕЗ MAC ЧЕРЕЗ GITHUB:
1. Создай пустой GitHub repository.
2. Загрузи туда СОДЕРЖИМОЕ этой папки (включая .github).
3. Открой Actions -> Build BLEP MAP IPA -> Run workflow.
4. После завершения скачай artifact BLEP_MAP_ALTSTORE_IPA.
5. Распакуй artifact — внутри BLEP_MAP_ALTSTORE.ipa.
6. Открой IPA через AltStore.

ВАЖНО:
- Если server.js работает только на твоём домашнем ПК, приложение работает пока ПК включён
  и iPhone имеет доступ к этому адресу.
- Для работы BLEP MAP откуда угодно сервер нужно поставить на VPS/домен HTTPS.
- AltStore сам подписывает IPA. В этом проекте сборка специально создаётся unsigned.
- iOS не даст обычному AltStore-приложению бесконечно передавать GPS после полного закрытия
  приложения без отдельной background-location реализации и соответствующих ограничений iOS.
