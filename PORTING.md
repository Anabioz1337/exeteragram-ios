# План порта exteraGram на Telegram-iOS

База: upstream (Telegram-iOS 13.1.1, master fb0e62ba8a). Реализация идёт в ветку `extera-port`.

## Этапы

1. **Preferences layer** — слой настроек форка поверх существующей TelegramPreferences/UserDefaultsPersistence: собственный persistence-домен, типизированные ключи фич.
2. **Settings section** — отдельная секция настроек форка в списке настроек нативной UI-архитектурой Telegram-iOS (ViewController + STM/etc.), вход из Settings.
3. **Локализация** — механизм строк форка без правки общих локализационных файлов Telegram-iOS; свои .lproj-таблицы и слой подстановки.
4. **Модули фич** — порт фич exteraGram как отдельных submodules/subprojects в корневом Bazel (`MODULE.bazel` + BUILD), минимальные точки интеграции в core-модулях.
5. **Плагин-движок (CPython)** — встраивание CPython для плагинов: сборка интерпретатора через bazel, API-мост Swift↔Python, sandbox и lifecycle плагинов.
6. **Unsigned ipa сборка** — CI-сборка без код-сайнинга (fake-codesigning) уже в `.github/workflows/build.yml`; поддерживать пайплайн под новые модули.
