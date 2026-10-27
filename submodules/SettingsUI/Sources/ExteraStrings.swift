import Foundation
import TelegramPresentationData

// The extera strings live here instead of the generated PresentationStrings pipeline because
// the server-side language packs cannot know fork-local keys: English and Russian are the only
// deliverable localizations, resolved by the account's language code.
private struct ExteraStringsTable {
    let settingsTitle: String
    let speedHeader: String
    let downloadBoost: String
    let uploadBoost: String
    let boostOff: String
    let boostFast: String
    let boostUltra: String
    let ultraWarning: String
    let interfaceHeader: String
    let disableNumberRounding: String
    let formatTimeWithSeconds: String
    let storageHeader: String
    let customSaveFolder: String
    let customSaveFolderHint: String
    let analyticsHeader: String
    let useGoogleAnalytics: String
    let useGoogleCrashlytics: String
    let analyticsInfo: String
    let updatesHeader: String
    let checkForUpdates: String
    let checkingForUpdates: String
    let upToDate: String
    let checkFailed: String
    let checkOnLaunch: String
    let lastCheck: String
    let never: String
    let currentVersion: String
    let latestVersion: String
    let updateAvailable: String
    let updateAvailableText: (String) -> String
    let laterAction: String
    let downloadAction: String
    let downloadOnGitHub: String
    let restartRequired: String
    let restartRequiredText: String
}

private let exteraStringsEnglish = ExteraStringsTable(
    settingsTitle: "exteraGram",
    speedHeader: "Speed",
    downloadBoost: "Download Speed Boost",
    uploadBoost: "Upload Speed Boost",
    boostOff: "Off",
    boostFast: "Fast",
    boostUltra: "Ultra",
    ultraWarning: "Ultra boost can cause problems on slow networks.",
    interfaceHeader: "Interface",
    disableNumberRounding: "Disable Number Rounding",
    formatTimeWithSeconds: "Format Time with Seconds",
    storageHeader: "Storage",
    customSaveFolder: "Custom Save Folder",
    customSaveFolderHint: "Media will be saved to this album.",
    analyticsHeader: "Analytics",
    useGoogleAnalytics: "Google Analytics",
    useGoogleCrashlytics: "Google Crashlytics",
    analyticsInfo: "When these options are enabled, data about the device is collected.",
    updatesHeader: "Updates",
    checkForUpdates: "Check for Updates",
    checkingForUpdates: "Checking for Updates…",
    upToDate: "Up to Date",
    checkFailed: "Check Failed",
    checkOnLaunch: "Check on Launch",
    lastCheck: "Last Check",
    never: "Never",
    currentVersion: "Current Version",
    latestVersion: "Version",
    updateAvailable: "Update Available",
    updateAvailableText: { version in
        return "Version \(version) is available."
    },
    laterAction: "Later",
    downloadAction: "Download",
    downloadOnGitHub: "Download on GitHub",
    restartRequired: "Restart Required",
    restartRequiredText: "Restart the app to apply the changes."
)

private let exteraStringsRussian = ExteraStringsTable(
    settingsTitle: "exteraGram",
    speedHeader: "Скорость",
    downloadBoost: "Увеличение скорости загрузки",
    uploadBoost: "Увеличение скорости отдачи",
    boostOff: "Выкл",
    boostFast: "Быстро",
    boostUltra: "Ультра",
    ultraWarning: "Ультра-ускорение может вызывать проблемы на медленном интернете.",
    interfaceHeader: "Интерфейс",
    disableNumberRounding: "Не сокращать числа",
    formatTimeWithSeconds: "Формат времени с секундами",
    storageHeader: "Хранилище",
    customSaveFolder: "Своё сохранение в папку",
    customSaveFolderHint: "Медиа сохраняется в этот альбом.",
    analyticsHeader: "Аналитика",
    useGoogleAnalytics: "Google Analytics",
    useGoogleCrashlytics: "Google Crashlytics",
    analyticsInfo: "Когда эти опции включены, данные об устройстве собираются.",
    updatesHeader: "Обновления",
    checkForUpdates: "Проверить обновления",
    checkingForUpdates: "Ищем обновления…",
    upToDate: "Установлена последняя версия",
    checkFailed: "Ошибка проверки",
    checkOnLaunch: "Проверять при запуске",
    lastCheck: "Последняя проверка",
    never: "Никогда",
    currentVersion: "Текущая версия",
    latestVersion: "Версия",
    updateAvailable: "Доступно обновление",
    updateAvailableText: { version in
        return "Доступна версия \(version)."
    },
    laterAction: "Позже",
    downloadAction: "Скачать",
    downloadOnGitHub: "Скачать с GitHub",
    restartRequired: "Требуется перезапуск",
    restartRequiredText: "Перезапустите приложение, чтобы применить изменения."
)

public func exteraStrings(languageCode: String) -> ExteraStringsTable {
    return languageCode == "ru" ? exteraStringsRussian : exteraStringsEnglish
}

public func exteraStrings(presentationData: PresentationData) -> ExteraStringsTable {
    return exteraStrings(languageCode: presentationData.strings.primaryComponent.languageCode)
}
