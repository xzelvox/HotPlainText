# HotPlainText

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | **Español**

Copia como texto sin formato con un atajo (⌃⌘C). App para la barra de menús de macOS.

Una pequeña herramienta que quita el formato (colores, negrita, enlaces, etc.) del texto que copias de la web y de otros sitios, y deja solo el texto.

## Antecedentes

### El problema

Al pasar de Windows a Mac, lo que más me molestaba era copiar con formato.
Cuando copias un texto de una página web y lo pegas, se vienen con él los colores, los tamaños de letra, los enlaces y la negrita.

En Windows bastaba con pegarlo en el Bloc de notas y volver a copiarlo para obtener texto limpio, porque el Bloc de notas no puede guardar formato.
Y funciona así desde el principio, sin configurar nada.

En Mac, Notas y TextEdit conservan el formato, así que el mismo truco no sirve.
Puedes acercarte cambiando TextEdit a texto sin formato o reasignando atajos de teclado, pero en todos los casos tienes que cambiar la configuración tú mismo.
Algo que en Windows funcionaba sin más, en Mac necesita configuración.

### Qué hacen otras personas

En Mac, estas son las principales formas:

- **⌥⇧⌘V (Pegar con el mismo estilo)**: viene con macOS. Pero las teclas son incómodas y algunas apps no lo admiten.
- **Cambiar ⌘V por «Pegar con el mismo estilo»**: se puede asignar en Ajustes del Sistema, pero solo funciona en las apps que tienen ese elemento de menú.
- **Apps de la barra de menús que quitan el formato automáticamente al copiar**: Pure Paste, Rinse, PlainText – Clipboard Cleaner, entre otras.
- **Funciones de las apps de historial del portapapeles**: Raycast, Alfred, Maccy y otras pueden «pegar como texto sin formato».
- **Herramientas que lo quitan al copiar**: CleanBoard (pulsar ⌘C dos veces) y Plaintext! (⌃⌫ después de ⌘C).

Probé varias apps, pero ninguna me convenció.
La mayoría quitan el formato al pegar o lo quitan de todo lo que copias.
Yo quería copiar sin formato con una sola pulsación, y copiar con formato también con una sola pulsación.
No encontré nada así, así que lo hice yo.

### Decisiones tomadas por el camino

1. **Primero, una versión web**: pegar en un campo que no puede guardar formato y volver a copiar (la misma idea que el Bloc de notas de Windows). Sigue en `index.html`.
2. **Luego, una app para Mac**: una ventana que hace lo mismo.
3. **Un atajo que funciona en cualquier app**: selecciona texto y púlsalo para copiarlo sin formato. Elegí **⌃⌘C**. Es solo añadir ⌃ al ⌘C de siempre, así que es fácil de recordar, y no choca con macOS ni con las apps principales.
   - Descartados: ⌘X (Cortar), ⌘B (Negrita), ⌃C (detiene un comando en Terminal), ⌥⌘C (Copiar como nombre de ruta en el Finder).
4. **Intercambiar ⌘C y ⌃⌘C**: si quieres que el ⌘C de siempre copie sin formato, una casilla del menú los intercambia. El panel de la parte superior del menú muestra en todo momento qué hace cada tecla.
5. **7 idiomas**: inglés, japonés, chino (simplificado), coreano, alemán, francés y español.

## App para Mac (HotPlainText)

- En cualquier app, selecciona texto y pulsa **⌃⌘C** para copiarlo sin formato (requiere el permiso de accesibilidad)
- Al pegar en la ventana, el formato desaparece. «Pegar» pega y «Copiar» copia sin formato (la selección si la hay; si no, todo)
- Desde la barra de menús puedes cambiar «Intercambiar ⌘C y ⌃⌘C», «Abrir al iniciar sesión» e «Idioma»

### Instalación

Compílala en tu propio Mac e instálala. Como la app se compila en ese Mac, no aparece el aviso de que no se puede verificar el desarrollador.

Requisitos: macOS 14 o posterior y las Command Line Tools de Xcode (si no las tienes, ejecuta `xcode-select --install`).

```bash
git clone https://github.com/xzelvox/HotPlainText.git
cd HotPlainText/HotPlainText && ./install.sh
```

`install.sh` compila la app, cierra y elimina el HotPlainText anterior si lo hay, y después instala y abre el nuevo. Con una firma ad hoc también borra el permiso de accesibilidad anterior, así que vuelve a darlo cuando la app te lo pida.

Durante la compilación aparece un aviso en japonés que indica que se usará una firma ad hoc. Es normal; puedes ignorarlo.

La primera vez que abras la app, te mostrará cómo dar el permiso de accesibilidad que necesita ⌃⌘C. Sigue los pasos: cuando el permiso esté activado, la app se volverá a abrir sola. Cuando el panel de la parte superior del menú muestre un punto verde y «Accesibilidad: permitida», ya puedes usarla.

Para actualizar, ejecuta `git pull` y luego `./install.sh` de nuevo.

El icono se dibuja con `make_icon.swift`.

La app está disponible en inglés, japonés, chino (simplificado), coreano, alemán, francés y español, y sigue el idioma configurado en tu Mac (inglés si tu idioma no está disponible). También puedes elegir uno en «Idioma» del menú.
Los textos están en `*.lproj/Localizable.strings` (el inglés es el idioma base y sus claves se muestran tal cual). La tabla con todas las traducciones está en `HotPlainText/TRANSLATIONS.md`.

## Versión web

Abre `index.html` en un navegador, pega el texto y pulsa «すべてコピー» (Copiar todo). La versión web solo está en japonés.
