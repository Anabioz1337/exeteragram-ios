# exeteragram-ios

Кастомная сборка Telegram для iOS: база — [TelegramMessenger/Telegram-iOS](https://github.com/TelegramMessenger/Telegram-iOS), поверх портируются фичи форков [exteraGram](https://github.com/Alexanderworkmanager/exteraGram) и [AyuGram](https://github.com/AyuGram/AyuGram4A) / AyuGram iOS.

Сборка — через GitHub Actions на macos-runner, результат: **unsigned .ipa** (подпись пользователь накладывает сам, локально или через AltStore/sideloading).

## Структура

| Каталог | Назначение |
| --- | --- |
| `src/TGA` | Рабочий клон базы Telegram-iOS |
| `src/EXTG` | Клон exteraGram (Android, источник фич и референсов логики) |
| `src/TGI` | Клон Telegram-iOS для экспериментов сборки |

Рабочие клоны будут залиты позже; на данный момент каталоги заполняются параллельно и в репозиторий пока не добавлены. Анализ вытянутого APK лежит вне этой репы (`ref/`, `scripts/`).

## Сборка в CI

Черновик workflow: `.github/workflows/build.yml` (macos-14, ручной запуск + пуш). Настоящие команды сборки уточняются после первой пробы — рабочая база это текущий пайплайн официального Telegram-iOS: `python3 build-system/Make/Make.py` (Bazel) c генерацией Xcode-проекта, далее сборка без код-сайнинга и упаковка Payload в .ipa.

## Не подписано и без секретов

В репозитории нет сертификатов, provisioning profiles и секретов. Для release-сборки под своим Apple ID их нужно подключить отдельно.
