import AppKit
import Carbon
import ServiceManagement

// 画面に出る文字は、言語ファイル(en.lproj / ja.lproj の Localizable.strings)から読む
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

// 貼り付けた文字から書式を取り除くだけの小さなエディタ。
// 常駐中は、どのアプリでも ⌃⌘C で選んだ文字を「文字だけ」でコピーできる。
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var textView: NSTextView!
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    let countLabel = NSTextField(labelWithString: String(format: L("%d characters"), 0))
    let axItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let loginItem = NSMenuItem(title: L("Launch at login"), action: nil, keyEquivalent: "")
    var lastChangeCount = NSPasteboard.general.changeCount
    let swapItem = NSMenuItem(title: L("Swap ⌘C and ⌃⌘C"), action: nil, keyEquivalent: "")
    // メニューの上の札(今の割り当てと許可の状態)
    let header = MenuHeaderView()
    let headerItem = NSMenuItem()
    let languageItem = NSMenuItem(title: L("Language"), action: nil, keyEquivalent: "")
    // 選べる言語(名前はその言語で書く。"" はシステムと同じ)
    let languages: [(code: String, name: String)] = [
        ("en", "English"), ("ja", "日本語"), ("zh-Hans", "简体中文"), ("ko", "한국어"),
        ("de", "Deutsch"), ("fr", "Français"), ("es", "Español"),
    ]
    var keepFormatNext = false   // 入れ替え中の ⌃⌘C: 次のコピーは書式を残す

    // ⌘C と ⌃⌘C を入れ替えるか(初期値はオフ)。オンのときは ⌘C が文字だけ、⌃⌘C が書式付きになる
    var swapCopy: Bool {
        get { UserDefaults.standard.bool(forKey: "swapCopy") }
        set { UserDefaults.standard.set(newValue, forKey: "swapCopy") }
    }


    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        buildStatusItem()
        registerHotKey()
        startWatchingClipboard()

        // 書式を持てない入力欄にする(Windows のメモ帳と同じ動き)
        let scroll = NSTextView.scrollableTextView()
        textView = (scroll.documentView as! NSTextView)
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        NotificationCenter.default.addObserver(self, selector: #selector(updateCount),
                                               name: NSText.didChangeNotification, object: textView)

        let pasteButton = NSButton(title: L("Paste"), target: self, action: #selector(pasteText))
        let copyButton = NSButton(title: L("Copy"), target: self, action: #selector(copyPlain))
        copyButton.keyEquivalent = "\r"
        copyButton.keyEquivalentModifierMask = .command   // ⌘Return でもコピー
        let clearButton = NSButton(title: L("Clear"), target: self, action: #selector(clearAll))

        let bar = NSStackView(views: [pasteButton, copyButton, clearButton, NSView(), countLabel])
        bar.orientation = .horizontal
        bar.spacing = 8

        let root = NSStackView(views: [bar, scroll])
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        bar.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -24).isActive = true
        scroll.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -24).isActive = true

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "HotPlainText"
        window.contentView = root
        window.isReleasedWhenClosed = false   // 閉じても常駐し、あとで開き直せるようにする
        window.center()
        window.setFrameAutosaveName("PlainTextMain")
        // 開き直す前に書きかけだった文字を戻す
        if let text = UserDefaults.standard.string(forKey: "pendingText") {
            UserDefaults.standard.removeObject(forKey: "pendingText")
            textView.string = text
            updateCount()
        }
        showWindow()

        // 許可がまだのときは、起動時に付け方の案内を出す
        if !AXIsProcessTrusted() {
            DispatchQueue.main.async { [weak self] in self?.showAccessibilityGuide() }
            // 許可が付いたら開き直す(起動中のアプリからは、開き直すまで ⌃⌘C の中で送る ⌘C が届かないため)。
            // 案内の画面が出ている間も確かめられるよう、common モードで回す
            let timer = Timer(timeInterval: 1, repeats: true) { timer in
                MainActor.assumeIsolated {
                    guard AXIsProcessTrusted() else { return }
                    timer.invalidate()
                    (NSApp.delegate as? AppDelegate)?.relaunch()
                }
            }
            timer.tolerance = 0.1
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    // ウインドウを閉じても終了しない(常駐)
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // Dock のアイコンを押したらウインドウを出す
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return true
    }

    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(textView)
        NSApp.activate()
    }

    @objc func updateCount() {
        countLabel.stringValue = String(format: L("%d characters"), textView.string.count)
    }

    // 入力欄に貼り付ける(入力欄が書式を持てないので、文字だけになる)
    @objc func pasteText() {
        window.makeFirstResponder(textView)
        textView.paste(nil)
    }

    // 「コピー」ボタンとアプリ内の ⌃⌘C: 選んだ部分を文字だけでコピー。何も選んでいなければ全文
    @objc func copyPlain() {
        let range = textView.selectedRange()
        if range.length > 0 {
            writePlain((textView.string as NSString).substring(with: range))
        } else {
            writePlain(textView.string)
        }
    }

    func writePlain(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastChangeCount = pb.changeCount   // 自分で書いた分は監視で拾わない
        countLabel.stringValue = L("Copied")
        flashStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.updateCount() }
    }

    @objc func clearAll() {
        textView.string = ""
        updateCount()
        window.makeFirstResponder(textView)
    }

    // MARK: クリップボードの監視(許可は要らない)

    func startWatchingClipboard() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            MainActor.assumeIsolated { (NSApp.delegate as? AppDelegate)?.checkClipboard() }
        }
    }

    func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        // ほかの Mac からユニバーサルクリップボードで届いたものには手を出さない(書き直すと、その Mac に送り返されて上書きしてしまう)
        if isRemote(pb) { return }
        if keepFormatNext {   // 入れ替え中の ⌃⌘C で取ったものは、書式付きのまま残す
            keepFormatNext = false
            return
        }
        guard swapCopy, let types = pb.types else { return }

        let raw = Set(types.map(\.rawValue))
        // パスワードなど隠すべきもの、画像・ファイルのコピーには手を出さない
        let skip: Set<String> = ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType",
                                 "public.file-url", "public.png", "public.tiff", "public.jpeg"]
        guard raw.isDisjoint(with: skip) else { return }
        // 書式の付いた文字のときだけ入れ替える
        let rich: Set<String> = ["public.rtf", "public.html", "com.apple.flat-rtfd", "com.apple.webarchive",
                                 "NeXT Rich Text Format v1.0 pasteboard type", "Apple HTML pasteboard type"]
        guard !raw.isDisjoint(with: rich), let text = pb.string(forType: .string) else { return }
        writePlain(text)
    }

    // ほかの Apple 機器からユニバーサルクリップボードで届いたものか
    func isRemote(_ pb: NSPasteboard) -> Bool {
        pb.types?.contains(NSPasteboard.PasteboardType("com.apple.is-remote-clipboard")) ?? false
    }

    @objc func toggleSwap() {
        swapCopy.toggle()
        swapItem.state = swapCopy ? .on : .off
        updateKeyInfo()
    }

    // ⌘C と ⌃⌘C が、いまそれぞれ何をするかを出す
    func updateKeyInfo() {
        header.update(swap: swapCopy, trusted: AXIsProcessTrusted())
    }

    // ログイン項目への登録・解除(状態は Mac 側が覚えている)
    @objc func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = L("Couldn’t change Launch at login")
            alert.informativeText = String(format: L("%@\nPlease set it in System Settings › General › Login Items & Extensions."), error.localizedDescription)
            NSApp.activate()
            alert.runModal()
        }
    }

    // MARK: どのアプリでも効く ⌃⌘C

    func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { (NSApp.delegate as? AppDelegate)?.hotKeyPressed() }
            }
            return noErr
        }, 1, &spec, nil, nil)

        let id = EventHotKeyID(signature: OSType(0x50545854), id: 1)   // 'PTXT'
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_C), UInt32(cmdKey | controlKey), id,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("⌃⌘C の登録に失敗しました: \(status)")
        }
    }

    func hotKeyPressed() {
        // このアプリが前面なら、ほかのアプリへ送らずにそのままコピーする
        if NSApp.isActive {
            copyPlain()
            return
        }
        guard AXIsProcessTrusted() else {
            showAccessibilityGuide()
            return
        }

        // ⌃ や ⌘ を押したままだと、送った ⌘C が ⌃⌘C として届いてしまうので、指が離れるのを待つ
        waitForKeysUp(tries: 40)
    }

    // アクセシビリティの許可の付け方を案内する
    @objc func showAccessibilityGuide() {
        let alert = NSAlert()
        alert.messageText = L("⌃⌘C needs Accessibility permission")
        alert.informativeText = L("accessibility.guide")
        alert.addButton(withTitle: L("Open System Settings"))
        alert.addButton(withTitle: L("Close"))
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    // 最大 2 秒、0.05 秒ごとに修飾キーが離れたかを確かめる
    func waitForKeysUp(tries: Int) {
        let held = CGEventSource.flagsState(.combinedSessionState)
            .intersection([.maskControl, .maskCommand, .maskAlternate, .maskShift])
        if held.isEmpty || tries == 0 {
            sendCopy()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.waitForKeysUp(tries: tries - 1)
        }
    }

    // 前面のアプリに ⌘C を送り、クリップボードが変わったら文字だけに入れ替える。
    // 入れ替え中は、書式付きのまま残す
    func sendCopy() {
        let pb = NSPasteboard.general
        let before = pb.changeCount
        let plain = !swapCopy
        keepFormatNext = !plain
        let src = CGEventSource(stateID: .privateState)
        for down in [true, false] {
            let e = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: down)
            e?.flags = .maskCommand
            e?.post(tap: .cghidEventTap)
        }
        waitForCopy(before: before, tries: 20, plain: plain)
    }

    // 最大 1 秒、0.05 秒ごとにクリップボードの変化を確かめる
    func waitForCopy(before: Int, tries: Int, plain: Bool) {
        let pb = NSPasteboard.general
        var before = before
        // ほかの Mac から届いた変化は、ここでのコピーではないので待ち続ける
        if pb.changeCount != before && isRemote(pb) { before = pb.changeCount }
        if pb.changeCount != before {
            if plain {
                if let text = pb.string(forType: .string) {
                    writePlain(text)
                }
            } else {
                // 書式付きのまま。監視に拾われないよう印を付けて、コピーできたことだけ知らせる
                lastChangeCount = pb.changeCount
                keepFormatNext = false
                flashStatus()
            }
            return
        }
        guard tries > 0 else {
            keepFormatNext = false
            // 何もコピーされなかった(文字を選んでいない、など)ことを音で知らせる
            NSSound.beep()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.waitForCopy(before: before, tries: tries - 1, plain: plain)
        }
    }

    // MARK: メニュー

    // メニューバーのアイコン(常駐の目印)
    func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "doc.plaintext", accessibilityDescription: "HotPlainText")
        let menu = NSMenu()
        menu.delegate = self
        headerItem.view = header
        menu.addItem(headerItem)
        updateKeyInfo()
        // 操作はキーボードでも選べるよう、札の中ではなく普通の項目にする
        swapItem.action = #selector(toggleSwap)
        swapItem.target = self
        swapItem.state = swapCopy ? .on : .off
        swapItem.image = NSImage(systemSymbolName: "arrow.up.arrow.down", accessibilityDescription: nil)
        menu.addItem(swapItem)
        // 許可がないときだけ出す
        axItem.title = L("Click for help")
        axItem.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: nil)
        axItem.action = #selector(showAccessibilityGuide)
        axItem.target = self
        menu.addItem(axItem)
        menu.addItem(.separator())
        loginItem.action = #selector(toggleLogin)
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(languageItem)
        languageItem.submenu = buildLanguageMenu()
        menu.addItem(.separator())
        menu.addItem(withTitle: L("Open Window"), action: #selector(showWindow), keyEquivalent: "").target = self
        menu.addItem(withTitle: L("Quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        statusItem.menu = menu
    }

    // 言語の選択肢。いま選ばれているものにチェックを付ける
    func buildLanguageMenu() -> NSMenu {
        let menu = NSMenu()
        let chosen = (UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?["AppleLanguages"] as? [String])?.first ?? ""
        let system = menu.addItem(withTitle: L("Same as System"), action: #selector(setLanguage(_:)), keyEquivalent: "")
        system.representedObject = ""
        system.target = self
        system.state = chosen.isEmpty ? .on : .off
        menu.addItem(.separator())
        for lang in languages {
            let item = menu.addItem(withTitle: lang.name, action: #selector(setLanguage(_:)), keyEquivalent: "")
            item.representedObject = lang.code
            item.target = self
            item.state = chosen == lang.code ? .on : .off
        }
        return menu
    }

    // 言語を変えて、アプリを開き直す(表示の言語は起動したときに決まるため)
    @objc func setLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        if code.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        // 開き直せないときは終了せず、次に起動したときから新しい言語になる
        relaunch()
    }

    // ⌃⌘C の登録がぶつからないよう、このアプリが終わってから開き直す。
    // 書きかけの文字は残しておき、開き直したときに戻す
    func relaunch() {
        if !textView.string.isEmpty {
            UserDefaults.standard.set(textView.string, forKey: "pendingText")
        }
        let pid = ProcessInfo.processInfo.processIdentifier
        let relaunch = Process()
        relaunch.executableURL = URL(fileURLWithPath: "/bin/sh")
        relaunch.arguments = ["-c", "while kill -0 \(pid) 2>/dev/null; do sleep 0.1; done; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        do {
            try relaunch.run()
            NSApp.terminate(nil)
        } catch {
            UserDefaults.standard.removeObject(forKey: "pendingText")
            NSSound.beep()
        }
    }

    // コピーできたら、メニューバーのアイコンを一瞬チェックにする
    func flashStatus() {
        statusItem.button?.image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: L("Copied"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.statusItem.button?.image = NSImage(systemSymbolName: "doc.plaintext", accessibilityDescription: "HotPlainText")
        }
    }

    // ⌘V などのショートカットはメニューが無いと効かないので作る
    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("Quit HotPlainText"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let fileItem = NSMenuItem()
        let file = NSMenu(title: L("File"))
        file.addItem(withTitle: L("Close Window"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileItem.submenu = file
        main.addItem(fileItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: L("Edit"))
        edit.addItem(withTitle: L("Undo"), action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: L("Redo"), action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: L("Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: L("Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        let plainCopy = edit.addItem(withTitle: L("Copy as Plain Text"), action: #selector(copyPlain), keyEquivalent: "c")
        plainCopy.keyEquivalentModifierMask = [.control, .command]
        plainCopy.target = self
        edit.addItem(withTitle: L("Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: L("Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)

        NSApp.mainMenu = main
    }
}

// メニューを開くたびに、アクセシビリティの許可の状態を出し直す
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        // 許可なしのときだけ、押すと付け方の案内を出す項目を見せる
        axItem.isHidden = AXIsProcessTrusted()
        updateKeyInfo()
    }
}

// メニューの上の札。表示だけで、押せるものは置かない(メニューの中の部品はキーボードで選べないため)。
// 大きさは開く前に決まり、開いている間は変わらない
final class MenuHeaderView: NSView {
    let cmdLabel = NSTextField(labelWithString: "")
    let ctrlLabel = NSTextField(labelWithString: "")
    let dot = NSImageView()
    let axLabel = NSTextField(labelWithString: "")
    let title = NSTextField(labelWithString: "HotPlainText")
    let badges = [KeyBadge("⌘C"), KeyBadge("⌃⌘C")]

    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        autoresizingMask = [.width]   // メニューが札より広いときは、札も横に伸ばしてそろえる

        let grid = NSGridView(views: [[badges[0], cmdLabel], [badges[1], ctrlLabel]])
        grid.rowSpacing = 6
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .fill   // キーの札の幅をそろえる
        for i in 0..<grid.numberOfRows { grid.row(at: i).yPlacement = .center }

        axLabel.textColor = .secondaryLabelColor
        let status = NSStackView(views: [dot, axLabel])
        status.spacing = 5

        let stack = NSStackView(views: [title, grid, status])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 9
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        // 札は左右 6pt・上下 4pt 内側に描く(普通の項目の選択の色と端をそろえる)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // 文言と点の色を出し直し、中身に合わせて大きさを決める。メニューが開く前に呼ぶ
    // 文字の大きさは、メニューの標準の文字(ふつうは 13pt)を基準に決める。Mac の設定で変わればついてくる
    func update(swap: Bool, trusted: Bool, base: CGFloat = NSFont.menuFont(ofSize: 0).pointSize) {
        title.font = .boldSystemFont(ofSize: base)
        for label in [cmdLabel, ctrlLabel] { label.font = .systemFont(ofSize: base - 1) }
        for badge in badges { badge.label.font = .systemFont(ofSize: base - 2, weight: .medium) }
        axLabel.font = .systemFont(ofSize: base - 2)
        dot.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: base * 0.55, weight: .regular))
        let plain = L("Plain-text copy"), normal = L("Copy with formatting")
        cmdLabel.stringValue = swap ? plain : normal
        ctrlLabel.stringValue = swap ? normal : plain
        let key = trusted ? "  Accessibility: Allowed" : "  Accessibility: Not allowed"
        axLabel.stringValue = L(key).trimmingCharacters(in: .whitespaces)
        dot.contentTintColor = trusted ? .systemGreen : .systemRed
        setFrameSize(fittingSize)   // 中身ぶんの幅と高さ
    }

    // 色は描くたびに標準の色から取る(ライト/ダークの切り替えについてくる)
    override func draw(_ dirtyRect: NSRect) {
        NSColor.quaternaryLabelColor.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 6, dy: 4), xRadius: 8, yRadius: 8).fill()
    }
}

// ⌘C などのキーを、枠の付いた小さな札で出す
final class KeyBadge: NSView {
    let label: NSTextField

    init(_ text: String) {
        label = NSTextField(labelWithString: text)
        super.init(frame: .zero)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.secondaryLabelColor.setStroke()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4).stroke()
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
