# Treesitter, autotag i Markdown

<a id="plugin-nvim-treesitter"></a>
## `nvim-treesitter`

**Co robi i po co:** instaluje przypięte parsery i uruchamia wbudowane podświetlanie oraz, gdy istnieje query, indent Treesitter. To gałąź `main` po przepisaniu API dla Neovim 0.12.

**Ładowanie lokalne:** `lazy=false`, bo ta wersja nie wspiera lazy-loadingu; build wykonuje `:TSUpdate`. Setup instaluje parsery i przy `FileType` wywołuje `vim.treesitter.start`.

**Konfigurowany zestaw parserów:** `lua`, `luadoc`, `printf`, `vim`, `vimdoc`, `go`, `python`, `typescript`, `tsx`, `javascript`, `html`, `markdown`, `markdown_inline`.

**Filetype z automatycznym startem:** `lua`, `vim`, `help`, `go`, `python`, `typescript`, `typescriptreact`, `javascript`, `javascriptreact`, `html`, `markdown`. Język `tsx` jest zarejestrowany dla `typescriptreact`.

**Polecenia:** `:TSInstall[!] {language...}`, `:TSInstallFromGrammar[!] {language...}`, `:TSUpdate [language...]`, `:TSUninstall {language...}`, `:TSLog`. Wariant `!` nadal wymaga co najmniej jednej nazwy języka.

**Mapowania:** ta konfiguracja nie włącza modułu incremental selection i nie instaluje żadnej tabeli skrótów selekcji. Nie należy przenosić mapowań ze starego API do tej rewizji.

**Wymagania:** Neovim 0.12+, `curl`, `tar`, kompilator C/C++ oraz `tree-sitter-cli >= 0.26.1`. Przypięta gałąź `main` używa `tree-sitter build` również przy zwykłej instalacji parsera. Po aktualizacji wtyczki parsery trzeba zaktualizować.

### Parser, query i funkcja to trzy osobne warstwy

1. Parser zamienia tekst na drzewo składniowe. Sama instalacja parsera nie włącza żadnego wyglądu ani mapowania.
2. Query opisuje, które węzły są highlightem, wcięciem, injection albo `locals`. Dla jednej funkcji może istnieć query, a dla innej nie.
3. Funkcję uruchamia Neovim lub konsument. Lokalny autocmd włącza highlight i eksperymentalny indent tylko dla wymienionych filetype.
4. Injections pozwalają parserowi HTML działać we fragmencie Markdown albo parserowi języka w fenced code block. Nie wymagają osobnego modułu konfiguracji.

Folding Treesitter nie jest lokalnie ustawiony, incremental selection starego `nvim-treesitter.configs` nie istnieje, a text objects nie są zainstalowaną osobną wtyczką. Query `locals` są natomiast wykorzystywane pośrednio przez nvim-dap-virtual-text.

### Tutorial: instalacja i inspekcja

1. Sprawdź narzędzia: `:echo executable('tree-sitter')`, `:echo executable('cc')`, `:echo executable('curl')`.
2. `:TSInstall html markdown markdown_inline` instaluje parsery asynchronicznie. `:TSLog` pokazuje pobieranie, generowanie i kompilację.
3. Otwórz plik i wykonaj `:InspectTree`, aby zobaczyć drzewo; `:Inspect` pokazuje capture/highlight pod kursorem.
4. Jeżeli parser istnieje, ale podświetlanie nie startuje, sprawdź czy filetype znajduje się na lokalnej liście i ręcznie porównaj `:lua vim.treesitter.start()`.
5. Po zmianie commita wtyczki wykonaj `:TSUpdate`, ponieważ parsery są zgodne z konkretnymi rewizjami definicji w pluginie.

`TSInstallFromGrammar` buduje z gramatyki i wymaga jeszcze pełniejszego toolchainu; zwykły użytkownik powinien preferować `TSInstall`. `TSUninstall` usuwa parser, co natychmiast odbiera funkcje zależne od niego, na przykład autotag lub render Markdown.

**Diagnostyka:** `:TSLog`, `:InspectTree`, `:set filetype?`, `:lua =vim.treesitter.language.get_lang(vim.bo.filetype)` oraz `:messages`. Błąd indent nie musi oznaczać błędu highlightu, bo to różne query.

**Źródła przypiętej rewizji:** [README gałęzi `main`](https://github.com/nvim-treesitter/nvim-treesitter/blob/7b6cc8949f9999c5ed91436cbe24aa5f99c42025/README.md), [help i polecenia](https://github.com/nvim-treesitter/nvim-treesitter/blob/7b6cc8949f9999c5ed91436cbe24aa5f99c42025/doc/nvim-treesitter.txt), [lista obsługiwanych języków](https://github.com/nvim-treesitter/nvim-treesitter/blob/7b6cc8949f9999c5ed91436cbe24aa5f99c42025/SUPPORTED_LANGUAGES.md).

<a id="plugin-nvim-ts-autotag"></a>
## `nvim-ts-autotag`

**Co robi i po co:** na podstawie Treesitter domyka tag po wpisaniu `>`, a po zmianie nazwy jednego tagu aktualizuje jego parę. Przydaje się w HTML, JSX/TSX, Vue, Svelte, XML, Markdown z HTML i innych wspieranych gramatykach.

**Ładowanie lokalne:** `BufReadPre` i `BufNewFile`, opcje domyślne. `enable_close=true`, `enable_rename=true`, `enable_close_on_slash=false`.

- **`>`**: Wstaw znak i domknij tag, gdy drzewo składniowe wskazuje start tag. **Kontekst:** wspierany filetype, `i`. **Stan:** **Kontekstowe**.
- **wyjście z Insert**: Rename sparowanego tagu. **Kontekst:** wspierany filetype. **Stan:** **Kontekstowe**.
- **`/`**: Automatyczne domknięcie po `</`. **Kontekst:** `i`. **Stan:** **Warunkowe/wyłączone** lokalnie.

Brak publicznych poleceń Ex i dodatkowych globalnych mapowań.

**Wymagania:** Neovim co najmniej 0.9.5 oraz parser odpowiadający filetype. Bieżąca konfiguracja zapewnia `html`; zapewnia też TSX, JavaScript i Markdown.

### Tutorial: domknięcie i rename

1. W HTML wpisz `<section` i zakończ `>`. Gdy drzewo rozpoznaje start tag, wtyczka dopisuje `</section>` i pozostawia kursor między tagami.
2. Ustaw kursor w nazwie tagu otwierającego, wykonaj `ciwarticle` i wyjdź z Insert. Sparowany tag zamykający powinien zmienić się na `</article>`.
3. Powtórz w TSX/JSX na prawidłowym elemencie. Sam parser `typescript` nie zastępuje `tsx`; lokalna rejestracja mapuje `typescriptreact` na parser TSX.
4. W Markdown funkcja zadziała tylko we fragmencie rozpoznanym jako HTML injection.

Wtyczka nie domyka dowolnego tekstu wyglądającego jak tag: potrzebuje poprawnego węzła parsera, respektuje elementy void/self-closing i własne konfiguracje języka. `enable_close_on_slash=false`, więc wpisanie samego `</` nie wywołuje lokalnego automatycznego zakończenia.

**Diagnostyka:** sprawdź `:set filetype?`, `:InspectTree`, obecność parsera i `:verbose imap >`. Nvim-ts-autotag mapuje `>` buforowo tylko w obsługiwanym kontekście. Nie ma polecenia Ex ani globalnego toggle; aliasy i per-filetype overrides są **Opcjonalnym upstream API**.

**Źródła przypiętej rewizji:** [README i lista języków](https://github.com/windwp/nvim-ts-autotag/blob/88c1453db4ba7dd24131086fe51fdf74e587d275/README.md), [konfiguracje tagów](https://github.com/windwp/nvim-ts-autotag/tree/88c1453db4ba7dd24131086fe51fdf74e587d275/lua/nvim-ts-autotag/config), [obsługa close/rename](https://github.com/windwp/nvim-ts-autotag/blob/88c1453db4ba7dd24131086fe51fdf74e587d275/lua/nvim-ts-autotag/internal.lua).

<a id="plugin-render-markdown"></a>
## `render-markdown.nvim`

**Co robi i po co:** renderuje nagłówki, listy, kod, checkboxy, tabele i callouty Markdown bez zmiany tekstu pliku. Ładuje się tylko dla filetype `markdown`.

**Konfiguracja lokalna:** renderowanie domyślnie aktywne, limit pliku 10 MB, tryby `n`, `c`, `v`, `i`, domyślne ikony nagłówków, lokalnie ustawione ikony list oraz code block o szerokości `block` z nazwą języka. Mapowanie Markdown-only `<leader>mr` wywołuje `RenderMarkdown buf_toggle`.

**Polecenia:** `:RenderMarkdown`, `:RenderMarkdown enable`, `buf_enable`, `disable`, `buf_disable`, `toggle`, `buf_toggle`, `get`, `set [true|false]`, `set_buf [true|false]`, `preview`, `log`, `expand`, `contract`, `debug`, `config`.

Wtyczka nie ma własnych domyślnych mapowań. `<leader>mr` jest **Aktywne lokalne** i ograniczone do Markdown.

**Wymagania:** parsery Treesitter `markdown` i `markdown_inline`; ikony korzystają z Nerd Font.

### Co jest renderowane lokalnie

Nagłówki, akapity, fenced i inline code, poziome linie, listy z ikonami `● ○ ◆ ◇`, checkboxy, cytaty, callouty GitHub/Obsidian, tabele, linki i komentarze HTML korzystają z defaultów. Code block ma lokalnie szerokość `block`, znak w signcolumn i nazwę języka.

LaTeX wymaga parsera `latex` oraz `utftex` albo `latex2text`, a frontmatter parsera YAML; te dodatki nie są w lokalnej liście parserów, więc należy je traktować jako **Warunkowe/wyłączone**. Completion checkboxów/calloutów przez wewnętrzny LSP również jest domyślnie wyłączone.

### Renderowany tekst a prawdziwy plik

Wtyczka używa conceal, extmarks, virtual text i highlightów; nie zmienia znaków zapisanych w pliku. Lokalnie renderuje także w Insert i Visual. Anti-conceal odsłania elementy na linii kursora, ale ponieważ `i` należy do `render_modes`, pełny surowy widok uzyskasz najpewniej przez `<leader>mr`.

### Tutorial: czytanie, edycja i preview

1. Otwórz `.md` mniejszy niż 10 MB. Sprawdź nagłówki, listy, kod, tabelę i linki.
2. `<leader>mr` przełącza tylko bieżący bufor. Porównaj render z surowym Markdown i ponownie włącz.
3. `:RenderMarkdown preview` otwiera renderowany podgląd obok, bez zmiany stanu głównego bufora.
4. `:RenderMarkdown expand` zwiększa o jeden margines anti-conceal nad i pod kursorem; `contract` go zmniejsza.
5. `:RenderMarkdown get` pokazuje stan, `set`/`toggle` zmienia stan globalny, a warianty `set_buf`/`buf_toggle` tylko bieżący bufor.

### Diagnostyka

- `:RenderMarkdown config` pokazuje różnice konfiguracji względem defaultów.
- `:RenderMarkdown debug` opisuje markery na bieżącej linii, a `:RenderMarkdown log` otwiera log.
- Brak całego renderu: sprawdź filetype, limit 10 MB, parsery `markdown` i `markdown_inline` oraz `:checkhealth render-markdown`.
- Brak pojedynczej funkcji: ustal jej parser/query lub opcjonalne executable; działające nagłówki nie dowodzą działania LaTeX.

**Źródła przypiętej rewizji:** [README i pełna konfiguracja](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/c54380dd4d8d1738b9691a7c349ecad7967ac12e/README.md), [help](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/c54380dd4d8d1738b9691a7c349ecad7967ac12e/doc/render-markdown.txt), [troubleshooting](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/c54380dd4d8d1738b9691a7c349ecad7967ac12e/doc/troubleshooting.md).
