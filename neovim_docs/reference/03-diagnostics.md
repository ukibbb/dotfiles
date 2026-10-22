<a id="diagnostyka"></a>
# Diagnostyka

## Kontrola bazowa

```sh
bash install.sh status
nvim --version
wezterm --version
git --version
command -v rg fd fzf jq stylua ruff tree-sitter gh govulncheck
command -v go node npm curl tar cc psql mysql sqlite3 duckdb sqlcmd
command -v lua-language-server pyright-langserver typescript-language-server mypy
command -v debugpy-adapter dlv js-debug-adapter distant claude
go version
cc --version
node --version
npm --version
```

Brak pojedynczego opcjonalnego executable nie musi blokować całego edytora. Przykładowo brak `mypy` wyłącza tylko lokalny lint Python.

## Neovim nie startuje lub wtyczka się nie ładuje

1. Uruchom `nvim --headless "+checkhealth" +qa` i zwykłe `:messages`.
2. Otwórz `:Lazy`, sprawdź błędy i commit problematycznej wtyczki. Do bezpiecznego powrotu do lockfile służy `:Lazy! restore`.
3. Uruchom `:checkhealth lazy`; dla startupu użyj `:Lazy profile`.
4. Gdy zniknęły kolory UI, wykonaj `:lua require("base46").load_all_highlights()`; funkcja ładuje wynik od razu. Restart służy dopiero do sprawdzenia czystego startu.
5. Sprawdź nadpisanie klawisza przez `:verbose nmap <leader>gf` albo odpowiednie `:verbose imap`, `:verbose xmap`, `:verbose smap`.

## LSP, completion, format i parsery

- **brak klienta LSP**: `:checkhealth vim.lsp`, `:lua =vim.lsp.get_clients({bufnr=0})`.
- **brak konkretnego serwera**: `:echo executable('lua-language-server')` z właściwą nazwą executable.
- **TypeScript nie trafia do implementacji**: upewnij się, że klient nazywa się `ts_ls`, potem `:verbose nmap gS`.
- **completion bez LSP/importu**: `:CmpStatus`, sprawdź etykietę `[LSP]`, capabilities i root projektu.
- **formatter nie działa**: `:ConformInfo`, `:echo executable('stylua')`, `:echo executable('ruff')`.
- **mypy się nie uruchamia**: zapisz plik Python, sprawdź `:messages` i `:echo executable('mypy')`.
- **brak parsera**: `:TSLog`, `:TSInstall {język}`, potem `:InspectTree`.
- **stary parser po zmianie rewizji**: `:TSUpdate`.
- **render Markdown nie działa**: `:RenderMarkdown config`, `:RenderMarkdown debug`, sprawdź `markdown` i `markdown_inline`.

## WezTerm i kod klawisza

1. Błędy konfiguracji pokazuje `Ctrl-Shift-l` (debug overlay); WezTerm przeładowuje `wezterm.lua` sam po zapisie, ręcznie `Ctrl-s r`.
2. Obejrzyj efektywne mapowania przez `wezterm show-keys`; tabele kluczy, w tym `resize_pane` i `copy_mode`, są wypisane osobno.
3. Gdy nawigacja nie przechodzi przez granicę Neovim, użyj `:checkhealth smart-splits`, a potem `wezterm cli list`, by sprawdzić panele.
4. Aby zobaczyć kod wysyłany przez terminal, wykonaj w Neovim `:lua print(vim.fn.keytrans(vim.fn.getcharstr()))`, zatwierdź i naciśnij badany klawisz.
5. Jeśli TUI pozostawiło w panelu mysz lub alternate screen, użyj `Ctrl-s Ctrl-g`; polecenie naprawcze zmienia stan terminala i powinno służyć tylko do tej awarii.

Jeśli `Ctrl-s` zamraża samą powłokę, sprawdź `stty -a` i ponownie wykonaj `stty -ixon`. W WezTerm `Ctrl-s` jest świadomie leaderem, więc dosłowny klawisz do aplikacji to `Ctrl-s Ctrl-s`.

## Git UI i różnice

- **Telescope nie widzi plików/tekstu**: `:checkhealth telescope`, potem `:echo executable('fd')` i `:echo executable('rg')`.
- **Neogit pokazuje błąd Git**: panel `$`/console, `:messages`, zwykłe `git status` w root repo.
- **Diffview ma zły zakres**: zamknij `:DiffviewClose`, sprawdź ref przez Git i podaj go jawnie do `:DiffviewOpen`.
- **CodeDiff nie ma biblioteki natywnej**: `:CodeDiff install`; wariant z `!` wymusza ponowną instalację.
- **operacja stage nie daje oczekiwanego wyniku**: natychmiast sprawdź `git status` i sekcję staged/unstaged przed dalszą akcją.

Nie diagnozuj problemu Git przez próbne `X`, discard albo hard reset. Najpierw użyj operacji tylko do odczytu: `git status`, diff i log.

## Gdzie pytać o mapowanie

- Neovim: `:map`, `:nmap`, `:imap`, `:xmap`, `:smap`, a dla źródła definicji `:verbose {tryb}map {klawisz}`.
- Lazy: `:Lazy help`, a potem `?` w UI konkretnej rewizji.
- Panel wtyczki: najpierw `g?` albo `?`, jeśli dana sekcja ten klawisz dokumentuje.
- WezTerm: `wezterm show-keys`; pamiętaj o osobnych tabelach `resize_pane` i `copy_mode`.
- Polecenia: `:help :commands`, `:command`, `:verbose command {nazwa}`; nazwa funkcji Lua z README nie oznacza automatycznie polecenia Ex.

Problemy z konkretną wtyczką: linia „Problemy” w jej opisie w [przewodniku po wtyczkach](../plugins/README.md#wtyczki).
