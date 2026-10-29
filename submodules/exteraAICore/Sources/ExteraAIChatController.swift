import Foundation
import UIKit
import SwiftSignalKit
import Display
import TelegramPresentationData
import PresentationDataUtils
import AccountContext

/// One exchange as it is shown in the conversation: either the user's own message
/// or the assistant's reply. History is intentionally kept in memory only.
public final class ExteraAIChatEntry: Equatable {
    let isUser: Bool
    var text: String

    init(isUser: Bool, text: String) {
        self.isUser = isUser
        self.text = text
    }

    public static func ==(lhs: ExteraAIChatEntry, rhs: ExteraAIChatEntry) -> Bool {
        return lhs.isUser == rhs.isUser && lhs.text == rhs.text
    }
}

public final class ExteraAIChatHistory {
    public static let shared = ExteraAIChatHistory()

    public private(set) var entries: [ExteraAIChatEntry] = []

    func append(_ entry: ExteraAIChatEntry) {
        self.entries.append(entry)
    }

    func updateLast(_ text: String) {
        guard let last = self.entries.last, !last.isUser else {
            return
        }
        last.text = text
    }

    func clear() {
        self.entries.removeAll()
    }
}

public func exteraAIChatController(context: AccountContext) -> ViewController {
    exteraAIEnsureCorrectionServiceRegistered()
    return ExteraAIChatController(context: context)
}

private final class ExteraAIChatController: ViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let context: AccountContext
    private var presentationTheme: PresentationTheme
    private let history = ExteraAIChatHistory.shared

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)

    private var isGenerating = false
    private var generationTask: Task<Void, Never>?

    init(context: AccountContext) {
        self.context = context
        self.presentationTheme = context.sharedContext.currentPresentationData.with { $0 }.theme
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationTheme, presentationStrings: context.sharedContext.currentPresentationData.with { $0 }.strings))
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = exteraAIString("Extera.AI.Title")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: exteraAIString("Extera.AI.Chat.Clear"),
            style: .plain,
            target: self,
            action: #selector(self.clearPressed)
        )

        self.view.backgroundColor = self.presentationTheme.chatList.backgroundColor
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelection = false
        self.tableView.keyboardDismissMode = .interactive
        self.view.addSubview(self.tableView)

        self.inputBar.backgroundColor = self.presentationTheme.chatList.backgroundColor
        self.inputField.placeholder = exteraAIString("Extera.AI.Chat.Placeholder")
        self.inputField.borderStyle = .roundedRect
        self.inputField.clearButtonMode = .whileEditing
        self.inputField.returnKeyType = .send
        self.inputField.delegate = self
        self.inputField.addTarget(self, action: #selector(self.inputChanged), for: .editingChanged)
        self.inputField.textColor = self.presentationTheme.list.itemPrimaryTextColor
        self.inputBar.addSubview(self.inputField)

        self.sendButton.setTitle(exteraAIString("Extera.AI.Chat.Send"), for: .normal)
        self.sendButton.isEnabled = false
        self.sendButton.tintColor = self.presentationTheme.list.itemAccentColor
        self.sendButton.addTarget(self, action: #selector(self.sendPressed), for: .touchUpInside)
        self.inputBar.addSubview(self.sendButton)

        self.view.addSubview(self.inputBar)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let barHeight: CGFloat = 52.0 + self.view.safeAreaInsets.bottom
        self.inputBar.frame = CGRect(x: 0.0, y: self.view.bounds.height - barHeight, width: self.view.bounds.width, height: barHeight)

        let horizontalInset: CGFloat = 12.0
        let fieldWidth = self.view.bounds.width - horizontalInset * 3.0 - 64.0
        self.inputField.frame = CGRect(x: horizontalInset, y: self.view.safeAreaInsets.bottom + 8.0, width: fieldWidth, height: 36.0)
        self.sendButton.frame = CGRect(x: self.view.bounds.width - horizontalInset - 64.0, y: self.view.safeAreaInsets.bottom + 8.0, width: 64.0, height: 36.0)

        self.tableView.frame = CGRect(x: 0.0, y: 0.0, width: self.view.bounds.width, height: self.view.bounds.height - barHeight)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let endValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) else {
            return
        }
        let overlap = max(0.0, endValue.cgRectValue.height - self.view.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration, animations: {
            self.additionalSafeAreaInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: overlap, right: 0.0)
            self.view.layoutIfNeeded()
        })
    }

    // MARK: Conversation

    @objc private func inputChanged() {
        self.sendButton.isEnabled = !(self.inputField.text ?? "").isEmpty
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.sendPressed()
        return false
    }

    @objc private func clearPressed() {
        let controller = textAlertController(
            context: self.context,
            title: nil,
            text: exteraAIString("Extera.AI.Chat.ClearInfo"),
            actions: [
                TextAlertAction(type: .genericAction, title: exteraAIString("Extera.AI.ResultClose"), action: {}),
                TextAlertAction(type: .destructiveAction, title: exteraAIString("Extera.AI.Chat.Clear"), action: { [weak self] in
                    self?.generationTask?.cancel()
                    self?.history.clear()
                    self?.tableView.reloadData()
                })
            ]
        )
        self.present(controller, in: .window(.root))
    }

    @objc private func sendPressed() {
        let text = (self.inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !self.isGenerating else {
            return
        }
        self.inputField.text = nil
        self.inputChanged()

        self.history.append(ExteraAIChatEntry(isUser: true, text: text))
        self.history.append(ExteraAIChatEntry(isUser: false, text: exteraAIString("Extera.AI.Chat.Thinking")))
        self.tableView.reloadData()
        self.scrollToBottom()

        let store = ExteraAIStore.shared
        let settings = store.generationSettings
        let role = store.selectedRole
        let resolved = exteraAIResolveBackend(store: store)

        self.isGenerating = true
        self.generationTask = Task { [weak self] in
            do {
                guard case .resolved(let backend) = resolved else {
                    throw ExteraAIGenerationFailure.request(.network)
                }
                let reply: String
                switch backend {
                case .onDevice:
                    reply = try await ExteraAIOnDeviceModel.respond(
                        system: role?.prompt ?? "",
                        user: text,
                        temperature: settings.temperature
                    ) { delta in
                        DispatchQueue.main.async {
                            let _ = self?.appendStreamingDelta(delta)
                            self?.refreshLastCell()
                        }
                    }
                case let .service(service):
                    guard let streamingController = self else {
                        return
                    }
                    reply = try await streamingController.streamServiceReply(
                        service: service,
                        role: role,
                        settings: settings,
                        userText: text
                    )
                }
                if reply.isEmpty {
                    throw ExteraAIGenerationFailure.request(.emptyResponse)
                }
                DispatchQueue.main.async {
                    self?.history.updateLast(reply)
                    self?.finishGeneration()
                }
            } catch {
                let texts = exteraAIErrorTexts(failure: error as? ExteraAIGenerationFailure ?? .request(.network))
                DispatchQueue.main.async {
                    self?.history.updateLast(texts.title + "\n" + texts.info)
                    self?.finishGeneration()
                }
            }
        }
    }

    private func streamServiceReply(
        service: ExteraAIServiceConfig,
        role: ExteraAIRoleConfig?,
        settings: ExteraAIGenerationSettings,
        userText: String
    ) async throws -> String {
        var messages: [ExteraAIChatMessage] = []
        if let prompt = role?.prompt, !prompt.isEmpty {
            messages.append(.system(prompt))
        }
        for entry in self.history.entries.dropLast() {
            messages.append(entry.isUser ? .user(entry.text) : .assistant(entry.text))
        }
        let client = ExteraAIChatClient()
        var reply = ""
        for try await event in client.chatStream(service: service, messages: messages, settings: settings) {
            if case .content(let delta) = event {
                reply += delta
                DispatchQueue.main.async {
                    self.refreshLastCell()
                }
            }
        }
        return reply
    }

    private func appendStreamingDelta(_ delta: String) -> String {
        if let last = self.history.entries.last {
            last.text += delta
            return last.text
        }
        return delta
    }

    private func finishGeneration() {
        self.isGenerating = false
        self.tableView.reloadData()
        self.scrollToBottom()
    }

    private func refreshLastCell() {
        if let last = self.history.entries.indices.last {
            let indexPath = IndexPath(row: last, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? ExteraAIChatMessageCell {
                cell.apply(entry: self.history.entries[last], theme: self.presentationTheme)
            }
        }
        self.scrollToBottom()
    }

    private func scrollToBottom() {
        guard !self.history.entries.isEmpty else {
            return
        }
        let indexPath = IndexPath(row: self.history.entries.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }

    // MARK: Table view

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.history.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ExteraAIChatMessageCell()
        cell.apply(entry: self.history.entries[indexPath.row], theme: self.presentationTheme)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let entry = self.history.entries[indexPath.row]
        let maxWidth = self.view.bounds.width * 0.78 - 32.0
        let size = (entry.text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: UIFont.systemFont(ofSize: 16.0)],
            context: nil
        )
        return ceil(size.height) + 20.0
    }
}

private final class ExteraAIChatMessageCell: UITableViewCell {
    private let messageLabel = UILabel()
    private var isUserEntry = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.messageLabel.numberOfLines = 0
        self.messageLabel.font = UIFont.systemFont(ofSize: 16.0)
        self.contentView.addSubview(self.messageLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(entry: ExteraAIChatEntry, theme: PresentationTheme) {
        self.isUserEntry = entry.isUser
        self.messageLabel.text = entry.text
        self.messageLabel.textColor = entry.isUser ? theme.list.itemAccentColor : theme.list.itemPrimaryTextColor
        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let inset: CGFloat = 12.0
        let maxWidth = self.contentView.bounds.width * 0.78
        let size = (self.messageLabel.text ?? "").boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: self.messageLabel.font as Any],
            context: nil
        )
        let width = ceil(size.width) + 16.0
        if self.isUserEntry {
            self.messageLabel.frame = CGRect(x: self.contentView.bounds.width - inset - width, y: 10.0, width: width, height: ceil(size.height))
        } else {
            self.messageLabel.frame = CGRect(x: inset, y: 10.0, width: width, height: ceil(size.height))
        }
        self.messageLabel.textAlignment = self.isUserEntry ? .right : .left
    }
}
