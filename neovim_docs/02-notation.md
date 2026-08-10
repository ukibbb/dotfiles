<a id="notacja"></a>
# Notacja i etykiety

## Tryby Neovim

- **`n`**: Normal.
- **`i`**: Insert.
- **`v`**: Visual **oraz Select**; tak działa tryb mapowania `v` w API Neovim.
- **`x`**: Tylko Visual, bez Select.
- **`s`**: Tylko Select.
- **`o`**: Operator-pending.
- **`c`**: Command-line.
- **`t`**: Terminal.

`n,x` oznacza dwa mapowania: Normal i tylko Visual. `i,s` oznacza Insert i Select. W nazwach klawiszy `C`, `M` i `S` oznaczają odpowiednio `Ctrl`, `Alt/Meta` i `Shift`.

## Etykiety stanu

- **Aktywne lokalne**: Mapowanie lub zachowanie rzeczywiście włączone przez to repozytorium.
- **Domyślne wtyczki**: Mapowanie instalowane przez przypiętą wtyczkę, bez lokalnej definicji.
- **Domyślne Neovim**: Mapowanie lub zachowanie dostarczane przez używaną wersję Neovim, niezależne od wtyczki.
- **Kontekstowe**: Działa tylko w określonym buforze, panelu, trybie, filetype albo po podłączeniu LSP.
- **Polecenie**: Publiczne polecenie Ex, które można wpisać po `:`; wewnętrzne funkcje Lua nie są tu nazywane poleceniami.
- **Przykład nieaktywny**: Skrót pokazany przez README jako przykład, ale nieutworzony przez tę konfigurację.
- **Warunkowe/wyłączone**: Istnieje tylko po spełnieniu warunku albo jest jawnie wyłączone.
- **Opcjonalne upstream**: Funkcja obecna w przypiętym kodzie, ale wymagająca dodatkowego mapowania, konfiguracji albo ręcznego API Lua.
- **Biblioteka bez samodzielnego UI**: Zależność używana przez inne wtyczki; użytkownik diagnozuje ją pośrednio, zamiast otwierać osobny panel.

## Klawisze fizyczne na macOS

WezTerm bezpośrednio koduje fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q`, `Cmd-\` i `Cmd--` jako sekwencje CSI-u widziane przez Neovim jako `Meta+Ctrl`. Dlatego konfiguracja Neovim zapisuje je jako `<M-C-H>`, `<M-C-L>`, `<M-C-Q>`, `<M-C-\>` i `<M-C-_>`. `Cmd-j` i `Cmd-k` są kodowane jako sekwencje używane przez mapowania `<M-j>` i `<M-k>`. W listach mapowań podano zarówno zamiar fizyczny, jak i kod Neovim tam, gdzie to potrzebne.
