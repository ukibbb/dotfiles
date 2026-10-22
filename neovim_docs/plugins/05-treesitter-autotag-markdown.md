# Treesitter, autotag i Markdown

<a id="plugin-nvim-treesitter"></a>
## `nvim-treesitter`

Instaluje parsery i włącza podświetlanie składni (oraz indent, gdzie jest query) przez Treesitter. Inne wtyczki (autotag, render-markdown, DBee, dap-virtual-text) korzystają z tych parserów. Gałąź `main` dla Neovim 0.12, bez incremental selection i bez mapowań.

Parsery: `lua`, `luadoc`, `printf`, `vim`, `vimdoc`, `go`, `html`, `markdown`, `markdown_inline`, `python`, `typescript`, `tsx`, `javascript`, `json`, `sql`. Highlight startuje automatycznie dla: lua, vim, help, go, html, markdown, python, typescript(react), javascript(react), json, sql.

- **`:TSInstall {język}`**: doinstaluj parser.
- **`:TSUpdate`**: zaktualizuj parsery — rób to po każdej aktualizacji wtyczki.
- **`:TSLog`**: log instalacji/kompilacji.
- **`:InspectTree`**: drzewo składni bieżącego pliku; **`:Inspect`**: highlight pod kursorem.

Uwaga: instalacja parserów wymaga `tree-sitter-cli`, kompilatora C, `curl` i `tar`. Nowy parser nie da podświetlania, dopóki filetype nie zostanie dopisany do listy w `nvim/lua/configs/treesitter.lua`.

<a id="plugin-nvim-ts-autotag"></a>
## `nvim-ts-autotag`

Automatycznie domyka i przemianowuje tagi HTML/JSX/TSX (także HTML wewnątrz Markdown). Działa tylko tam, gdzie Treesitter rozpoznaje tag.

- **`>`** (Insert): po `<section>` dopisuje `</section>` i zostawia kursor w środku.
- **zmiana nazwy tagu + wyjście z Insert**: np. `ciwarticle` na tagu otwierającym zmienia też zamykający.
- Wpisanie `</` niczego nie domyka (wyłączone).

Nie działa? Sprawdź `:set filetype?` i czy parser jest zainstalowany (`:InspectTree`).

<a id="plugin-render-markdown"></a>
## `render-markdown.nvim`

Renderuje w buforze Markdown nagłówki, listy, bloki kodu, checkboxy, tabele i callouty, bez zmiany tekstu pliku. Ładuje się tylko dla plików `.md` (do 10 MB) i renderuje także w Insert i Visual.

- **`<leader>mr`**: włącz/wyłącz renderowanie w bieżącym buforze (najprostszy sposób na surowy tekst).
- **`:RenderMarkdown preview`**: renderowany podgląd w oknie obok.
- **`:RenderMarkdown expand` / `contract`**: zwiększ / zmniejsz obszar wokół kursora pokazywany jako surowy tekst.

Problemy: `:checkhealth render-markdown` (wymaga parserów `markdown` i `markdown_inline`).
