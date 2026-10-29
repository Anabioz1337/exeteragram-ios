import Foundation
import TelegramPresentationData

// The extera strings live here instead of the generated PresentationStrings pipeline because
// the server-side language packs cannot know fork-local keys: English and Russian are the only
// deliverable localizations, resolved by the account's language code.
public struct ExteraStringsTable {
    public let settingsTitle: String
    public let speedHeader: String
    public let downloadBoost: String
    public let uploadBoost: String
    public let boostOff: String
    public let boostFast: String
    public let boostUltra: String
    public let ultraWarning: String
    public let interfaceHeader: String
    public let disableNumberRounding: String
    public let formatTimeWithSeconds: String
    public let pluginsRow: String
    public let storageHeader: String
    public let customSaveFolder: String
    public let customSaveFolderHint: String
    public let analyticsHeader: String
    public let useGoogleAnalytics: String
    public let useGoogleCrashlytics: String
    public let analyticsInfo: String
    public let updatesHeader: String
    public let checkForUpdates: String
    public let checkingForUpdates: String
    public let upToDate: String
    public let checkFailed: String
    public let checkOnLaunch: String
    public let lastCheck: String
    public let never: String
    public let currentVersion: String
    public let latestVersion: String
    public let updateAvailable: String
    public let updateAvailableText: (String) -> String
    public let laterAction: String
    public let downloadAction: String
    public let downloadOnGitHub: String
    public let restartRequired: String
    public let restartRequiredText: String
    public let messagesHeader: String
    public let blockAds: String
    public let hideShareButton: String
    public let showCopyPhotoButton: String
    public let showClearButton: String
    public let showSaveMessageButton: String
    public let showReportButton: String
    public let showHistoryButton: String
    public let groupsHeader: String
    public let permissionsShortcut: String
    public let administratorsShortcut: String
    public let membersShortcut: String
    public let recentActionsShortcut: String
    public let tabCounter: String
    public let hideAllChats: String
    public let tabIcons: String
    public let stickerShape: String
    public let hideStickerTime: String
    public let hideCategories: String
    public let hidePhotoCounter: String
    public let disablePlayback: String
    public let longDoubleTapSeek: String
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
    pluginsRow: "Plugins",
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
    restartRequiredText: "Restart the app to apply the changes.",
    messagesHeader: "Messages",
    blockAds: "Block Ads",
    hideShareButton: "Hide Forward Button",
    showCopyPhotoButton: "Show Copy Photo Action",
    showClearButton: "Always Show Message Deletion",
    showSaveMessageButton: "Save to Saved Messages Action",
    showReportButton: "Always Show Report Action",
    showHistoryButton: "Show History Action",
    groupsHeader: "Group Shortcuts",
    permissionsShortcut: "Permissions Shortcut",
    administratorsShortcut: "Administrators Shortcut",
    membersShortcut: "Members Shortcut",
    recentActionsShortcut: "Recent Actions Shortcut",
    tabCounter: "Numeric Tab Counters",
    hideAllChats: "Hide All Chats Tab",
    tabIcons: "Alternative Tab Icons",
    stickerShape: "Round Sticker Previews",
    hideStickerTime: "Hide Sticker Timestamp",
    hideCategories: "Hide Sticker Categories",
    hidePhotoCounter: "Hide Photo Counter",
    disablePlayback: "Disable Video Autoplay",
    longDoubleTapSeek: "Long Double-Tap Seek"
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
    pluginsRow: "Плагины",
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
    restartRequiredText: "Перезапустите приложение, чтобы применить изменения.",
    messagesHeader: "Сообщения",
    blockAds: "Блокировать рекламу",
    hideShareButton: "Скрывать кнопку пересылки",
    showCopyPhotoButton: "Кнопка копирования фото",
    showClearButton: "Всегда показывать удаление",
    showSaveMessageButton: "Кнопка сохранения в избранное",
    showReportButton: "Всегда показывать жалобу",
    showHistoryButton: "Показывать историю правок",
    groupsHeader: "Ярлыки групп",
    permissionsShortcut: "Ярлык разрешений",
    administratorsShortcut: "Ярлык администраторов",
    membersShortcut: "Ярлык участников",
    recentActionsShortcut: "Ярлык последних действий",
    tabCounter: "Числовые счётчики вкладок",
    hideAllChats: "Скрыть вкладку «Все чаты»",
    tabIcons: "Другие иконки вкладок",
    stickerShape: "Округлять превью стикеров",
    hideStickerTime: "Скрывать время на стикерах",
    hideCategories: "Скрывать категории стикеров",
    hidePhotoCounter: "Скрывать счётчик фото",
    disablePlayback: "Отключить автовоспроизведение видео",
    longDoubleTapSeek: "Длинная перемотка двойным тапом"
)

public func exteraStrings(languageCode: String) -> ExteraStringsTable {
    return languageCode == "ru" ? exteraStringsRussian : exteraStringsEnglish
}

public func exteraStrings(presentationData: PresentationData) -> ExteraStringsTable {
    return exteraStrings(languageCode: presentationData.strings.primaryComponent.languageCode)
}
