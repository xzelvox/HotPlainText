# HotPlainText

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | **Français** | [Español](README.es.md)

Copier en texte brut avec un raccourci (⌃⌘C). App pour la barre des menus de macOS.

Un petit outil qui supprime la mise en forme (couleurs, gras, liens, etc.) du texte que vous copiez depuis le Web ou ailleurs, pour ne garder que le texte.

## Contexte

### Le problème

En passant de Windows au Mac, ce qui m’a le plus gêné, c’est la copie avec mise en forme.
Quand on copie un texte d’une page Web et qu’on le colle, les couleurs, les tailles de police, les liens et le gras suivent.

Sous Windows, il suffisait de coller dans le Bloc-notes puis de recopier pour obtenir un texte propre, car le Bloc-notes ne peut pas conserver la mise en forme.
Et cela fonctionne d’emblée, sans aucun réglage.

Sur Mac, Notes et TextEdit conservent la mise en forme, donc la même astuce ne marche pas.
On peut s’en approcher en passant TextEdit en texte brut ou en réattribuant des raccourcis clavier, mais dans tous les cas, il faut modifier des réglages soi-même.
Ce qui fonctionnait tout seul sous Windows demande des réglages sur Mac.

### Ce que font les autres

Sur Mac, voici les principales approches :

- **⌥⇧⌘V (Coller et adapter le style)** : intégré à macOS. Mais les touches sont peu pratiques, et certaines apps ne le prennent pas en charge.
- **Remplacer ⌘V par « Coller et adapter le style »** : on peut l’attribuer dans Réglages Système, mais cela ne fonctionne que dans les apps qui ont cet élément de menu.
- **Apps de la barre des menus qui suppriment automatiquement la mise en forme après la copie** : Pure Paste, Rinse, PlainText – Clipboard Cleaner, entre autres.
- **Fonctions des apps d’historique du presse-papiers** : Raycast, Alfred, Maccy et d’autres savent « coller en texte brut ».
- **Outils qui la suppriment au moment de la copie** : CleanBoard (appuyer deux fois sur ⌘C) et Plaintext! (⌃⌫ après ⌘C).

J’ai essayé plusieurs apps, mais aucune ne m’a vraiment convaincu.
La plupart suppriment la mise en forme soit au moment de coller, soit sur tout ce qu’on copie.
Je voulais copier en texte brut d’une seule touche, et copier avec la mise en forme d’une seule touche aussi.
Je n’ai rien trouvé de tel, alors je l’ai fait.

### Décisions prises en chemin

1. **D’abord une version Web** : coller dans un champ qui ne peut pas conserver la mise en forme, puis recopier (la même idée que le Bloc-notes de Windows). Elle est toujours dans `index.html`.
2. **Ensuite une app Mac** : une fenêtre qui fait la même chose.
3. **Un raccourci qui fonctionne dans toutes les apps** : sélectionnez du texte et appuyez pour le copier en texte brut. J’ai choisi **⌃⌘C**. C’est simplement ⌃ ajouté au ⌘C habituel, donc facile à retenir, et il n’entre pas en conflit avec macOS ni avec les principales apps.
   - Écartés : ⌘X (Couper), ⌘B (Gras), ⌃C (arrête une commande dans Terminal), ⌥⌘C (Copier le chemin d’accès dans le Finder).
4. **Inverser ⌘C et ⌃⌘C** : si vous voulez que le ⌘C habituel copie en texte brut, une case à cocher dans le menu les inverse. Le panneau en haut du menu indique à tout moment ce que fait chaque touche.
5. **7 langues** : anglais, japonais, chinois (simplifié), coréen, allemand, français et espagnol.

## App Mac (HotPlainText)

- Dans n’importe quelle app, sélectionnez du texte et appuyez sur **⌃⌘C** pour le copier en texte brut (nécessite l’autorisation d’accessibilité)
- Coller dans la fenêtre supprime la mise en forme. « Coller » colle, et « Copier » copie en texte brut (la sélection s’il y en a une, sinon tout)
- Depuis la barre des menus, vous pouvez changer « Inverser ⌘C et ⌃⌘C », « Ouvrir à la connexion » et « Langue »

### Installation

Compilez l’app sur votre propre Mac et installez-la. Comme elle est compilée sur ce Mac, l’avertissement « impossible de vérifier le développeur » n’apparaît pas.

Prérequis : macOS 14 ou ultérieur, et les Command Line Tools de Xcode (si vous ne les avez pas, lancez `xcode-select --install`).

```bash
git clone https://github.com/xzelvox/HotPlainText.git
cd HotPlainText/HotPlainText && ./install.sh
```

`install.sh` compile l’app, quitte et supprime l’ancien HotPlainText s’il existe, puis installe et ouvre le nouveau. Avec une signature ad hoc, il efface aussi l’ancienne autorisation d’accessibilité : accordez-la de nouveau quand l’app vous le demande.

Pendant la compilation, un message en japonais indique qu’une signature ad hoc sera utilisée. C’est normal, vous pouvez l’ignorer.

À la première ouverture, l’app explique comment accorder l’autorisation d’accessibilité dont ⌃⌘C a besoin. Suivez les étapes : dès que l’autorisation est activée, l’app se rouvre toute seule. Quand le panneau en haut du menu affiche un point vert et « Accessibilité : autorisée », tout est prêt.

Pour mettre à jour, lancez `git pull`, puis de nouveau `./install.sh`.

L’icône est dessinée par `make_icon.swift`.

L’app est disponible en anglais, japonais, chinois (simplifié), coréen, allemand, français et espagnol, et suit la langue réglée sur votre Mac (anglais si votre langue n’est pas prise en charge). Vous pouvez aussi en choisir une dans « Langue » du menu.
Les textes se trouvent dans `*.lproj/Localizable.strings` (l’anglais est la langue de base, et ses clés s’affichent telles quelles). Le tableau de toutes les traductions se trouve dans `HotPlainText/TRANSLATIONS.md`.

## Version Web

Ouvrez `index.html` dans un navigateur, collez, puis cliquez sur « すべてコピー » (Tout copier). La version Web n’existe qu’en japonais.
