# HotPlainText

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md) | **Deutsch** | [Français](README.fr.md) | [Español](README.es.md)

Mit einem Tastenkürzel (⌃⌘C) als reinen Text kopieren. App für die macOS-Menüleiste.

Ein kleines Werkzeug, das die Formatierung (Farben, Fettschrift, Links usw.) von Text entfernt, den du aus dem Web oder anderswo kopierst, und nur den Text übrig lässt.

## Hintergrund

### Das Problem

Nach dem Umstieg von Windows auf den Mac hat mich das Kopieren mit Formatierung am meisten gestört.
Wenn man Text von einer Webseite kopiert und einsetzt, kommen Farben, Schriftgrößen, Links und Fettschrift mit.

Unter Windows konnte man den Text in den Editor einfügen und erneut kopieren, um sauberen Text zu bekommen, denn der Editor kann keine Formatierung speichern.
Und das funktioniert von Anfang an, ganz ohne Einstellungen.

Auf dem Mac behalten „Notizen“ und „TextEdit“ die Formatierung bei, deshalb klappt derselbe Trick nicht.
Man kommt nahe heran, indem man TextEdit auf reinen Text umstellt oder Tastenkürzel neu belegt, aber in jedem Fall muss man selbst Einstellungen ändern.
Was unter Windows einfach so ging, braucht auf dem Mac erst Einstellungen.

### Wie andere es machen

Auf dem Mac gibt es vor allem diese Wege:

- **⌥⇧⌘V (Einsetzen und Stil anpassen)**: in macOS eingebaut. Die Tasten sind aber unhandlich, und manche Apps unterstützen es nicht.
- **⌘V auf „Einsetzen und Stil anpassen“ legen**: lässt sich in den Systemeinstellungen zuweisen, funktioniert aber nur in Apps, die diesen Menüpunkt haben.
- **Menüleisten-Apps, die die Formatierung nach dem Kopieren automatisch entfernen**: Pure Paste, Rinse, PlainText – Clipboard Cleaner und andere.
- **Funktionen von Zwischenablage-Verlaufs-Apps**: Raycast, Alfred, Maccy und andere können „als reinen Text einsetzen“.
- **Werkzeuge, die schon beim Kopieren entfernen**: CleanBoard (⌘C zweimal drücken) und Plaintext! (⌃⌫ nach ⌘C).

Ich habe mir einige Apps angesehen, aber keine hat mich überzeugt.
Die meisten entfernen die Formatierung entweder beim Einsetzen oder bei allem, was man kopiert.
Ich wollte reinen Text mit einem Tastendruck kopieren und mit Formatierung ebenfalls mit einem Tastendruck.
So etwas habe ich nicht gefunden, also habe ich es selbst gebaut.

### Entscheidungen unterwegs

1. **Zuerst eine Web-Version**: in ein Eingabefeld einsetzen, das keine Formatierung speichern kann, und erneut kopieren (dieselbe Idee wie der Windows-Editor). Sie liegt noch in `index.html`.
2. **Dann eine Mac-App**: ein Fenster, das dasselbe tut.
3. **Ein Tastenkürzel, das in jeder App funktioniert**: Text auswählen und drücken, schon ist er als reiner Text kopiert. Ich habe **⌃⌘C** gewählt. Es ist einfach ⌃ zum gewohnten ⌘C dazu, also leicht zu merken, und es kollidiert nicht mit macOS oder wichtigen Apps.
   - Verworfen: ⌘X (Ausschneiden), ⌘B (Fett), ⌃C (beendet einen Befehl im Terminal), ⌥⌘C (Pfadnamen kopieren im Finder).
4. **⌘C und ⌃⌘C tauschen**: falls das gewohnte ⌘C als reiner Text kopieren soll, lassen sich die beiden über ein Häkchen im Menü tauschen. Das Feld oben im Menü zeigt jederzeit, was welche Taste tut.
5. **7 Sprachen**: Englisch, Japanisch, Chinesisch (vereinfacht), Koreanisch, Deutsch, Französisch und Spanisch.

## Mac-App (HotPlainText)

- In jeder App Text auswählen und **⌃⌘C** drücken, um ihn als reinen Text zu kopieren (erfordert die Berechtigung für Bedienungshilfen)
- Beim Einsetzen ins Fenster verschwindet die Formatierung. „Einsetzen“ setzt ein, „Kopieren“ kopiert als reinen Text (die Auswahl, falls vorhanden, sonst alles)
- In der Menüleiste lassen sich „⌘C und ⌃⌘C tauschen“, „Beim Anmelden starten“ und „Sprache“ umschalten

### Installation

Die App wird auf dem eigenen Mac gebaut und installiert. Weil sie auf diesem Mac gebaut wird, erscheint die Warnung „Der Entwickler kann nicht überprüft werden“ nicht.

Voraussetzungen: macOS 14 oder neuer und die Xcode Command Line Tools (falls nicht vorhanden: `xcode-select --install`).

```bash
git clone https://github.com/xzelvox/HotPlainText.git
cd HotPlainText/HotPlainText && ./install.sh
```

`install.sh` baut die App, beendet und entfernt ein älteres HotPlainText, falls vorhanden, und installiert und öffnet dann das neue. Bei einer Ad-hoc-Signatur löscht es außerdem die alte Berechtigung für Bedienungshilfen. Erteile sie also erneut, wenn die App danach fragt.

Beim Bauen erscheint ein Hinweis auf Japanisch, dass eine Ad-hoc-Signatur verwendet wird. Das ist in Ordnung und kann ignoriert werden.

Beim ersten Öffnen zeigt die App, wie man die Berechtigung für Bedienungshilfen erteilt, die ⌃⌘C braucht. Folge den Schritten. Sobald die Berechtigung aktiv ist, öffnet sich die App von selbst neu. Wenn das Feld oben im Menü einen grünen Punkt und „Bedienungshilfen: Erlaubt“ zeigt, ist alles bereit.

Zum Aktualisieren `git pull` und danach erneut `./install.sh` ausführen.

Das Symbol wird mit `make_icon.swift` gezeichnet.

Die App gibt es auf Englisch, Japanisch, Chinesisch (vereinfacht), Koreanisch, Deutsch, Französisch und Spanisch. Sie folgt der Spracheinstellung des Mac (Englisch, wenn die Sprache nicht unterstützt wird). Im Menü unter „Sprache“ lässt sich eine Sprache auch selbst wählen.
Die Texte stehen in `*.lproj/Localizable.strings` (Englisch ist die Basissprache, die Schlüssel werden direkt angezeigt). Eine Übersicht aller Übersetzungen steht in `HotPlainText/TRANSLATIONS.md`.

## Web-Version

`index.html` im Browser öffnen, Text einsetzen und auf „すべてコピー“ (Alles kopieren) klicken. Die Web-Version gibt es nur auf Japanisch.
