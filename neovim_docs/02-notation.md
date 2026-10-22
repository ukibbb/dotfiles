<a id="notacja"></a>
# Notacja

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

## Klawisze fizyczne na macOS

WezTerm bezpośrednio koduje fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q`, `Cmd-\` i `Cmd--` jako sekwencje CSI-u widziane przez Neovim jako `Meta+Ctrl`. Dlatego konfiguracja Neovim zapisuje je jako `<M-C-H>`, `<M-C-L>`, `<M-C-Q>`, `<M-C-\>` i `<M-C-_>`. `Cmd-j` i `Cmd-k` są kodowane jako sekwencje używane przez mapowania `<M-j>` i `<M-k>`. W listach mapowań podano zarówno zamiar fizyczny, jak i kod Neovim tam, gdzie to potrzebne.
