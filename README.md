# HotPlainText

**English** | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [Español](README.es.md)

Copy as plain text with a hotkey (⌃⌘C). macOS menu bar app.

A small tool that strips the formatting (colors, bold, links and so on) from text you copy from the web and other places, leaving only the text.

## Background

### The problem

After moving from Windows to Mac, the thing that bothered me most was copying with formatting.
When you copy text from a web page and paste it, the colors, font sizes, links and bold come along with it.

On Windows, you could paste into Notepad and copy again to get clean text, because Notepad can't hold formatting.
And it works that way out of the box, with no setup.

On the Mac, Notes and TextEdit keep the formatting, so the same trick doesn't work.
You can get close by switching TextEdit to plain text or by reassigning keyboard shortcuts, but all of these mean changing settings yourself.
Something that just worked on Windows needs setup on the Mac.

### What other people do

On the Mac, these are the main approaches:

- **⌥⇧⌘V (Paste and Match Style)**: built into macOS. The keys are awkward, though, and some apps don't support it.
- **Remapping ⌘V to "Paste and Match Style"**: you can assign it in System Settings, but it only works in apps that have that menu item.
- **Menu bar apps that strip formatting automatically after you copy**: Pure Paste, Rinse, PlainText – Clipboard Cleaner and others.
- **Clipboard history apps**: Raycast, Alfred, Maccy and others can "paste as plain text".
- **Tools that strip it on the copy side**: CleanBoard (press ⌘C twice) and Plaintext! (⌃⌫ after ⌘C).

I tried several apps, but none of them felt right to me.
Most either strip formatting when you paste, or strip it from everything you copy.
I wanted plain-text copy in one keystroke, and copy with formatting in one keystroke too.
I couldn't find anything like that, so I made it.

### Decisions made along the way

1. **A web version first**: paste into an input that can't hold formatting, then copy again (the same idea as Windows Notepad). It's still in `index.html`.
2. **Then a Mac app**: a window that does the same thing.
3. **A shortcut that works in every app**: select text and press it to copy as plain text. I chose **⌃⌘C**. It's just ⌃ added to the usual ⌘C, so it's easy to remember, and it doesn't clash with macOS or major apps.
   - Ruled out: ⌘X (Cut), ⌘B (Bold), ⌃C (stops a command in Terminal), ⌥⌘C (Copy as Pathname in Finder).
4. **Swapping ⌘C and ⌃⌘C**: for when you want the usual ⌘C to be the plain-text copy, a checkbox in the menu swaps them. The panel at the top of the menu always shows what each key does.
5. **7 languages**: English, Japanese, Chinese (Simplified), Korean, German, French and Spanish.

## Mac app (HotPlainText)

- In any app, select text and press **⌃⌘C** to copy it as plain text (requires Accessibility permission)
- Pasting into the window removes formatting. "Paste" pastes, and "Copy" copies as plain text (the selection if there is one, otherwise everything)
- From the menu bar you can switch "Swap ⌘C and ⌃⌘C", "Launch at login" and "Language"

### Installation

Build it on your own Mac and install it. Because the app is built on that Mac, you won't see the "can't verify the developer" warning.

Requirements: macOS 14 or later, and the Xcode Command Line Tools (if you don't have them, run `xcode-select --install`).

```bash
git clone https://github.com/xzelvox/HotPlainText.git
cd HotPlainText/HotPlainText && ./install.sh
```

`install.sh` builds the app, quits and removes any older HotPlainText, then installs and opens the new one. With an ad-hoc signature it also clears the old Accessibility permission, so grant it again when the app asks.

During the build, a note in Japanese appears saying it will use an ad-hoc signature. That's fine; you can ignore it.

The first time you open the app, it shows how to grant the Accessibility permission that ⌃⌘C needs. Once you've followed the steps and the permission is on, the app reopens by itself. When the panel at the top of the menu shows a green dot and "Accessibility: Allowed", you're ready.

To update, run `git pull` and then `./install.sh` again.

The icon is drawn by `make_icon.swift`.

The app is available in English, Japanese, Chinese (Simplified), Korean, German, French and Spanish, and follows your Mac's language setting (English if your language isn't supported). You can also choose one from "Language" in the menu.
The text lives in `*.lproj/Localizable.strings` (English is the base language, and its keys are shown as-is). A table of all translations is in `HotPlainText/TRANSLATIONS.md`.

## Web version

Open `index.html` in a browser, paste, and press "すべてコピー" (Copy all). The web version is in Japanese only.
