import Foundation
import SwiftSignalKit
import Display
import UIKit
import TelegramPresentationData
import AccountContext

final class ExteraPluginCodeScreen: ViewController {
    private let context: AccountContext
    private let initialCode: String
    private let save: (String) -> Void
    private var disposable: Disposable?
    private var textView: UITextView?

    init(context: AccountContext, code: String, save: @escaping (String) -> Void) {
        self.context = context
        self.initialCode = code
        self.save = save

        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: presentationData.theme, presentationStrings: presentationData.strings))

        self.navigationPresentation = .modal
        self.navigationItem.title = presentationData.strings.Extera_Plugins_CodeEditor_Title
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: presentationData.strings.Common_Done,
            style: .done,
            target: self,
            action: #selector(self.donePressed)
        )
        self.disposable = (context.sharedContext.presentationData |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.textView?.textColor = presentationData.theme.list.itemPrimaryTextColor
            self.textView?.keyboardAppearance = presentationData.theme.overallDarkAppearance ? .dark : .light
        })
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.disposable?.dispose()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: 13.0, weight: .regular)
        textView.textColor = presentationData.theme.list.itemPrimaryTextColor
        textView.backgroundColor = .clear
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardAppearance = presentationData.theme.overallDarkAppearance ? .dark : .light
        textView.keyboardDismissMode = .interactive
        textView.text = self.initialCode
        self.view.addSubview(textView)
        self.textView = textView
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        guard let textView = self.textView else {
            return
        }
        let contentInsets = layout.insets(options: [.statusBar, .input])
        let navigationHeight = self.navigationLayout(layout: layout).navigationFrame.maxY
        textView.frame = CGRect(origin: CGPoint(x: 8.0, y: navigationHeight + 8.0), size: CGSize(width: layout.size.width - 16.0, height: max(120.0, layout.size.height - navigationHeight - contentInsets.bottom - 16.0)))
    }

    @objc private func donePressed() {
        if let textView = self.textView {
            self.save(textView.text ?? "")
        }
        if let navigationController = self.navigationController as? NavigationController {
            _ = navigationController.popViewController(animated: true)
        }
    }
}

public func exteraPluginCodeScreen(context: AccountContext, code: String, save: @escaping (String) -> Void) -> ViewController {
    return ExteraPluginCodeScreen(context: context, code: code, save: save)
}
