# Zarządzanie, UI i infrastruktura

<a id="plugin-lazy-nvim"></a>
## `lazy.nvim`

**Co robi i po co:** menedżer wtyczek. Rozwiązuje zależności, ładuje moduły na żądanie, instaluje i przywraca dokładne rewizje z lockfile.

**Ładowanie lokalne:** `nvim/init.lua` bootstrapuje `folke/lazy.nvim` do `~/.local/share/nvim/lazy/lazy.nvim`, dodaje katalog do runtimepath i wywołuje `require("lazy").setup("plugins", ...)`. `defaults.lazy=true` oznacza ładowanie na żądanie. `event`, `ft`, `cmd` i `keys` są właśnie wyzwalaczami takiego ładowania; `lazy=false` ładuje wtyczkę przy starcie. Brakujące wtyczki są instalowane automatycznie i ustawiane na commit z lockfile. Sprawdzanie aktualizacji jest wyłączone, a wykrywanie zmiany specyfikacji pozostaje aktywne, tylko bez notyfikacji.

**Polecenia:** `:Lazy` lub `:Lazy show`, `:Lazy home`, `:Lazy install`, `:Lazy update`, `:Lazy sync`, `:Lazy clean`, `:Lazy check`, `:Lazy log`, `:Lazy restore`, `:Lazy profile`, `:Lazy debug`, `:Lazy help`, `:Lazy health`, `:Lazy load {plugin}`, `:Lazy build {plugin}`, `:Lazy reload {plugin}`, `:Lazy clear`. Wariant `:Lazy!` czeka na ukończenie operacji; dla `load` omija też sprawdzenie `cond`.

### Co naprawdę robią operacje

- **`check`**: Wykonuje fetch i pokazuje dostępne zmiany, ale ich nie checkoutuje.
- **`install`**: Instaluje brakujące katalogi i zapisuje osiągnięty stan do lockfile.
- **`update`**: Aktualizuje wskazane wtyczki i zapisuje nowe commity do lockfile.
- **`sync`**: Łączy install, clean i update; nie jest poleceniem do wiernego odtworzenia repo.
- **`restore`**: Ustawia wtyczki zgodnie z lockfile; dla commita pod kursorem może także przepiąć lockfile.
- **`clean`**: Usuwa instalacje nieobecne w specyfikacji i może przepisać lockfile.
- **`build`**: Uruchamia zadeklarowany build, czyli potencjalnie kod Lua lub polecenie powłoki.
- **`reload`**: Eksperymentalnie przeładowuje wtyczkę; pełny restart jest pewniejszy.
- **`clear`**: Czyści zakończone zadania z widoku, nie usuwa cache ani wtyczek.

- **`Enter`**: Szczegóły wtyczki. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`K`**: Hover. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`d`**: Diff. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`q`**: Zamknięcie. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`I` / `i`**: Instalacja brakujących / wskazanej. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`U` / `u`**: Aktualizacja wszystkich / wskazanej i zapis lockfile. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`S`**: Install + clean + update. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`X` / `x`**: Clean zbędnych / usunięcie wskazanej instalacji. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`C` / `c`**: Sprawdzenie aktualizacji wszystkich / wskazanej. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`L` / `gl`**: Log zmian. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`R` / `r`**: Przywrócenie z lockfile. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`P`, `D`, `?`, `H`**: Profile, debug, help, home. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`gx`**: To samo co kontekstowe `K`: README, help, repo, issue albo commit. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.
- **`gb`**: Wymuszenie build wskazanej wtyczki. **Kontekst UI Lazy:** wtyczka. **Stan:** **Domyślne wtyczki**.
- **`<localleader>i`**: Inspekcja pełnego obiektu specyfikacji. **Kontekst UI Lazy:** wtyczka. **Stan:** **Domyślne wtyczki**; zwykle `\i`.
- **`<localleader>t`**: Terminal w katalogu wtyczki. **Kontekst UI Lazy:** wtyczka. **Stan:** **Domyślne wtyczki**; zwykle `\t`.
- **`<localleader>l`**: Log przez `lazygit`, jeśli program jest dostępny. **Kontekst UI Lazy:** wtyczka. **Stan:** **Kontekstowe**; zwykle `\l`.
- **mała litera akcji**: Operacja na kilku zaznaczonych wtyczkach. **Kontekst UI Lazy:** zaznaczenie Visual. **Stan:** **Kontekstowe**.
- **`Ctrl-s` / `Ctrl-f`**: Sortowanie / filtr. **Kontekst UI Lazy:** profil. **Stan:** **Kontekstowe**; w tmux dosłowny klawisz wymaga `Ctrl-s Ctrl-s`.
- **`Ctrl-c`**: Przerwanie. **Kontekst UI Lazy:** zadanie. **Stan:** **Kontekstowe**.
- **`[[` / `]]`**: Poprzednia / następna sekcja. **Kontekst UI Lazy:** lista. **Stan:** **Domyślne wtyczki**.

### Tutorial: kontrola i wierne odtworzenie

1. Otwórz `:Lazy` i sprawdź, czy sekcje błędów albo brakujących instalacji są puste.
2. Naciśnij `?`, aby zobaczyć mapowania dokładnie tej rewizji, oraz `Enter` na wtyczce, aby rozwinąć jej commit, zależności i czasy ładowania.
3. Na nowej maszynie wykonaj `:Lazy! restore`. Bang czeka na koniec, a `restore` respektuje `nvim/lazy-lock.json`.
4. Zamknij i ponownie uruchom Neovim. `:Lazy health` sprawdzi sam menedżer, a `:Lazy profile` pokaże koszt startu.

### Tutorial: bezpieczna aktualizacja jednej wtyczki

1. Wykonaj `:Lazy check nazwa`, przeczytaj log i diff bez zmiany checkoutu.
2. Uruchom `:Lazy update nazwa`, nie globalne `sync`, jeżeli chcesz ograniczyć zakres.
3. Zrestartuj Neovim i przetestuj funkcje zależne od wtyczki.
4. W powłoce sprawdź `git diff -- nvim/lazy-lock.json`; nowy hash jest częścią zmiany, którą trzeba świadomie zaakceptować.
5. Przy regresji wykonaj `:Lazy! restore nazwa`, zrestartuj i ponownie sprawdź lockfile.

### Diagnostyka i bezpieczeństwo

- `:Lazy debug` pokazuje runtimepath i źródło specyfikacji, a `:Lazy log nazwa` historię ostatnich zmian.
- Gołe biblioteki bez wyzwalacza mogą zostać doładowane przy pierwszym `require()`, dlatego „niezaładowana przy starcie” nie oznacza „nieużywana”.
- Domyślne `local_spec=true` pozwala projektowi zaproponować `.lazy.lua`. Lazy używa `vim.secure.read`; przed udzieleniem zaufania przeczytaj plik, bo specyfikacja może uruchamiać kod i buildy.
- `install`, `update`, `restore`, `clean` i `sync` mogą przepisać lockfile. `clean` usuwa katalogi, a `build` uruchamia kod. Do odtworzenia tego repo używaj `restore`.

**Źródła przypiętej rewizji:** [help `lazy.nvim.txt`](https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/doc/lazy.nvim.txt), [polecenia UI](https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/lua/lazy/view/commands.lua), [obsługa lockfile](https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/lua/lazy/manage/lock.lua).

<a id="plugin-ui"></a>
## `ui`

**Co robi i po co:** przypięty `nvchad/ui` dostarcza statusline, tabufline, renamer LSP, dashboard, cheatsheet, picker motywów, automatyczne signature help i podgląd kolorów. Ładuje się natychmiast (`lazy=false`). Lokalny `chadrc.lua` włącza tabufline i statusline, pokazuje względną ścieżkę pliku i używa motywu `ayu_dark`.

**Aktywne lokalne:** `<leader>th` otwiera picker motywów; `<leader>ra` po attach LSP otwiera renamer; `<leader>b`, fizyczne `Cmd-h`, `Cmd-l`, `Cmd-q` sterują tabufline.

**Polecenia:** `:Nvdash`, `:NvCheatsheet`, `:MasonInstallAll`. Ostatnie próbuje zebrać narzędzia z konfiguracji LSP, Conform i nvim-lint, ale nie obejmuje adapterów DAP ani aktualizacji już zainstalowanych pakietów. Na świeżym starcie, zanim konfiguracje LSP zostaną załadowane, pierwszy przebieg może wykryć tylko formatery i lintery; najpierw otwórz obsługiwany plik albo użyj jawnej listy `:MasonInstall`.

- **`Ctrl-n` / `Down`, `Ctrl-p` / `Up`**: Następny / poprzedni motyw. **Kontekst:** picker motywów, `i`. **Stan:** **Kontekstowe**.
- **`j` / `Down`, `k` / `Up`**: Następny / poprzedni motyw. **Kontekst:** picker motywów, `n`. **Stan:** **Kontekstowe**.
- **`Enter`**: Zapis wybranego motywu w `chadrc.lua` i zamknięcie. **Kontekst:** picker motywów, `i,n`. **Stan:** **Kontekstowe**.
- **`Ctrl-w`**: Usunięcie poprzedniego słowa promptu. **Kontekst:** picker motywów, `i`. **Stan:** **Kontekstowe**.
- **`Esc`**: Anulowanie i usunięcie popupu. **Kontekst:** renamer, `i,n`. **Stan:** **Kontekstowe**.
- **`q` / `Esc`**: Zamknięcie. **Kontekst:** cheatsheet. **Stan:** **Kontekstowe**.

### Co pokazują statusline i tabufline

- Statusline pokazuje tryb, ikonę i względną ścieżkę, branch i statystyki Gitsigns, diagnostykę, klienta LSP, katalog roboczy oraz pozycję. Przy małej szerokości mniej ważne moduły znikają.
- Tabufline pojawia się dopiero przy co najmniej dwóch listowanych buforach albo kartach. Każda karta utrzymuje własny zestaw buforów.
- Kliknięcie nazwy przełącza bufor, ikona zamknięcia go zamyka, a zmodyfikowany plik wywołuje `confirm bd`. Zamknięty terminal jest ukrywany zamiast zabijania procesu i można go odnaleźć przez `:Telescope terms`.
- Przycisk przełączania motywu w tabufline używa pary `theme_toggle`. Lokalny `ayu_dark` nie należy do domyślnej pary `onedark`/`one_light`, dlatego korzystaj z `<leader>th`.

### Tutorial: motyw, dashboard i cheatsheet

1. Naciśnij `<leader>th`. W Insert filtruj nazwę, poruszaj się `Ctrl-n` / `Ctrl-p`; po `Esc` używaj `j/k`.
2. `Enter` zapisuje wybór przez tekstową zmianę `nvim/lua/chadrc.lua`. Po wyborze sprawdź diff tego pliku. Zamknięcie bez zatwierdzenia przywraca zapisany motyw.
3. Wpisz `:Nvdash`. W dashboardzie działają lokalne `ff`, `fo`, `fw`, `th`, `ch`, `j/k` i `Enter`, bez leadera. Polecenie nie jest skonfigurowane jako ekran startowy.
4. Otwórz `:NvCheatsheet`. Lista jest budowana z aktywnych mapowań mających `desc`; nie zastępuje `:verbose map`, bo pomija część trybów i `<Plug>`.

### Tutorial: rename i automatyczna pomoc LSP

1. W buforze z podłączonym LSP ustaw kursor na symbolu i użyj `<leader>ra`.
2. Wpisz nową nazwę i zatwierdź `Enter`; pusta lub niezmieniona nazwa nic nie robi, a `Esc` anuluje.
3. Rename może zmienić wiele buforów lub plików workspace. Zapisz je i obejrzyj `git diff`.
4. Podczas wpisywania argumentów funkcji UI może automatycznie otwierać signature help po znakach triggerujących serwera. Jest to niezależne od ręcznego `Ctrl-s` Neovim.

### Colorify i terminale

- Aktywne domyślnie `colorify` rozpoznaje `#RRGGBB`, dodaje próbkę inline i może pytać LSP o `documentColor`. Nie ma lokalnego toggle; przy problemach wydajnościowych kontroluje je opcja `M.colorify.enabled` w `chadrc.lua`.
- Moduł terminali NvChad oraz `:Telescope terms` istnieją w kodzie, lecz repo nie definiuje launchera terminala NvChad. Przykładowe `<leader>pt` z README jest **Przykładem nieaktywnym**.

**Wymagania:** `base46`, `volt`, ikony z `nvim-web-devicons` i czcionka Nerd Font. Renamer wymaga serwera LSP obsługującego rename.

**Diagnostyka:** `:verbose nmap <leader>th`, `:verbose nmap <leader>ra`, `:NvCheatsheet`, `:messages` oraz `:lua =require("nvconfig").ui` pokazują odpowiednio źródło mapowań, aktywne opcje i błędy. Brak danych Git/LSP w statusline zwykle oznacza brak repo albo klienta, nie awarię całego UI.

**Źródła przypiętej rewizji:** [help `nvui.txt`](https://github.com/NvChad/ui/blob/aa95aca6936f277417d2565d9416713198b6dbd1/doc/nvui.txt), [picker motywów](https://github.com/NvChad/ui/blob/aa95aca6936f277417d2565d9416713198b6dbd1/lua/nvchad/themes/init.lua), [tabufline](https://github.com/NvChad/ui/tree/aa95aca6936f277417d2565d9416713198b6dbd1/lua/nvchad/tabufline), [colorify](https://github.com/NvChad/ui/tree/aa95aca6936f277417d2565d9416713198b6dbd1/lua/nvchad/colorify).

<a id="plugin-base46"></a>
## `base46`

**Co robi i po co:** silnik motywów NvChad. Build wtyczki generuje cache highlightów, a konfiguracja lokalna dogrywa cache dla statusline, blankline, składni, LSP, cmp, Git, Mason, Telescope i Treesitter. Nie ma własnych domyślnych mapowań ani publicznych poleceń użytkownika.

**Konfiguracja lokalna:** motyw `ayu_dark`, bez przezroczystości, z override'ami komentarzy, właściwości, typów, modułów, operatorów, wyjątków i interpunkcji. `require("base46").load_all_highlights()` jest API Lua używanym przez build, nie poleceniem Ex.

### Tutorial: wybór, inspekcja i naprawa kolorów

1. Do zwykłej zmiany użyj `<leader>th`; zapis trafia do `chadrc.lua`, nie tylko do bieżącej sesji.
2. Aby ustalić źródło koloru pod kursorem, użyj `:Inspect`; drzewo składni pokaże `:InspectTree`, a konkretną grupę `:hi NazwaGrupy`.
3. Gdy cache został usunięty lub jest niespójny, wykonaj `:Lazy build base46` albo `:lua require("base46").load_all_highlights()`.
4. `load_all_highlights()` kompiluje i natychmiast ładuje grupy, więc restart nie jest wymagany. Można go wykonać dopiero jako niezależny test czystego startu.

**Opcjonalne upstream:** `compile()` tylko generuje cache, `toggle_theme()` zapisuje przełączenie skonfigurowanej pary, a `toggle_transparency()` zapisuje zmianę przezroczystości. Oba toggle modyfikują `chadrc.lua` tekstowo i nie mają lokalnych mapowań.

**Źródła przypiętej rewizji:** [README](https://github.com/NvChad/base46/blob/884b990dcdbe07520a0892da6ba3e8d202b46337/README.md), [kompilacja i ładowanie](https://github.com/NvChad/base46/blob/884b990dcdbe07520a0892da6ba3e8d202b46337/lua/base46/init.lua).

<a id="plugin-volt"></a>
## `volt`

**Co robi i po co:** framework interaktywnych okien używany przez picker motywów, Minty, Menu i lokalny drawer `claude.nvim`. Nie oferuje samodzielnego launchera ani polecenia Ex.

- **`Ctrl-t`**: Cykliczna zmiana bufora/okna składowego. **Okno zbudowane na Volt:** bufor UI. **Stan:** **Kontekstowe**.
- **`q` / `Esc`**: Zamknięcie całego UI. **Okno zbudowane na Volt:** bufor UI. **Stan:** **Kontekstowe**.
- **`Enter`**: Uruchomienie elementu pod kursorem. **Okno zbudowane na Volt:** bufor zarejestrowany przez `volt.events.add()`. **Stan:** **Kontekstowe**.
- **`Tab` / `Shift-Tab`**: Następny / poprzedni wiersz z elementem klikalnym. **Okno zbudowane na Volt:** bufor zarejestrowany przez `volt.events.add()`. **Stan:** **Kontekstowe**.

### Jak używać Volta pośrednio

1. Otwórz `:Huefy`: Minty rejestruje interaktywne eventy, więc `Tab`, `Shift-Tab`, `Enter`, mysz i `Ctrl-t` działają.
2. Otwórz `<leader>th`: picker motywów używa własnych `Ctrl-n`/`Ctrl-p` i `j/k`; nie rejestruje eventów Volta, więc `Tab` nie jest tam nawigacją.
3. W drawerze Claude część skrótów pochodzi z samego drawera, a `Enter`/`Tab` w shellu z Volta. Zawsze pierwszeństwo ma opis konkretnego konsumenta.
4. `q` i `Esc` zamykają UI w Normal. W buforze promptu Insert litera `q` pozostaje tekstem; wyjdź do Normal albo użyj lokalnego skrótu zamknięcia.

Volt nie ma własnego health checku ani launchera. Gdy UI konsumenta nie powstaje, sprawdź `:Lazy`, `:messages` i stan tej konkretnej wtyczki.

**Źródła przypiętej rewizji:** [README](https://github.com/nvzone/volt/blob/620de1321f275ec9d80028c68d1b88b409c0c8b1/README.md), [wspólne mapowania](https://github.com/nvzone/volt/blob/620de1321f275ec9d80028c68d1b88b409c0c8b1/lua/volt/init.lua), [eventy interaktywne](https://github.com/nvzone/volt/blob/620de1321f275ec9d80028c68d1b88b409c0c8b1/lua/volt/events.lua).

<a id="plugin-menu"></a>
## `menu`

**Co robi i po co:** biblioteka kontekstowych, także zagnieżdżonych menu na Volt. Lokalna konfiguracja jej nie otwiera i nie definiuje `RightMouse` ani innego launchera.

- **`h` / `l`**: Poprzednia / następna kolumna-okno menu. **Stan:** **Kontekstowe**.
- **`Enter`**: Wykonanie pozycji pod kursorem. **Stan:** **Kontekstowe**.
- **`q` / `Esc`**: Zamknięcie przez Volt. **Stan:** **Kontekstowe**.
- **klawisz pokazany przy pozycji**: Bezpośrednie wykonanie pozycji. **Stan:** **Kontekstowe**.

Mapowania otwierające menu z README są **Przykładem nieaktywnym**. `require("menu").open(...)` jest API Lua, nie poleceniem Ex.

### Co jest dostępne, ale nieaktywne

Przypięta rewizja zawiera presety `default`, `nvimtree`, `gitsigns`, `lsp` i `neo-tree`. Można je otworzyć dopiero ręcznym API, na przykład `:lua require("menu").open("default")`. `h/l` przełącza kolumny, `Enter` wykonuje pozycję, `Tab` porusza się po klikalnych wierszach, a `q` zamyka.

Nie jest to bezpieczny „podgląd”: presety zawierają między innymi usunięcie treści bufora, operacje cut/paste/delete nvim-tree oraz reset Gitsigns. Nie otwieraj i nie wykonuj nieznanej pozycji tylko w celu sprawdzenia interfejsu. `nvzone/menu` jest inną biblioteką niż komponent `nui.menu` z `nui.nvim`.

**Tutorial użytkownika:** w bieżącej konfiguracji nie ma codziennego przepływu Menu. Pełne zrozumienie oznacza właśnie świadomość, że instalacja jest biblioteką opcjonalną, a skróty `RightMouse` i `Ctrl-t` z README nie istnieją lokalnie.

**Źródła przypiętej rewizji:** [README i przykładowe launchery](https://github.com/nvzone/menu/blob/7a0a4a2896b715c066cfbe320bdc048091874cc6/README.md), [presety](https://github.com/nvzone/menu/tree/7a0a4a2896b715c066cfbe320bdc048091874cc6/lua/menus), [mapowania menu](https://github.com/nvzone/menu/blob/7a0a4a2896b715c066cfbe320bdc048091874cc6/lua/menu/mappings.lua).

<a id="plugin-minty"></a>
## `minty`

**Co robi i po co:** dwa narzędzia kolorystyczne zbudowane na Volt: Huefy wybiera kolor, Shades generuje odcienie. Ładuje się dopiero po poleceniu.

**Polecenia:** `:Huefy`, `:Shades`.

- **`Ctrl-t`**: Zmiana składowego okna. **Kontekst:** Huefy/Shades. **Stan:** **Kontekstowe**, Volt.
- **`Tab` / `Shift-Tab`, `Enter`**: Wybór elementu klikalnego. **Kontekst:** Huefy/Shades. **Stan:** **Kontekstowe**, Volt.
- **`h` / `l`**: Ruch po suwaku. **Kontekst:** slider. **Stan:** **Kontekstowe**.
- **`Ctrl-s`**: Zastosowanie koloru w oryginalnym wierszu i zamknięcie. **Kontekst:** paleta. **Stan:** **Kontekstowe**; w tmux wyślij `Ctrl-s Ctrl-s`.
- **`q` / `Esc`**: Zamknięcie. **Kontekst:** UI. **Stan:** **Kontekstowe**.

**Wymagania:** `volt`, prawidłowe kolory terminala.

### Tutorial: Huefy

1. Ustaw kursor na istniejącym kodzie dokładnie w formacie `#RRGGBB`, na przykład `#61afef`, i uruchom `:Huefy`. Gdy pod kursorem nie ma poprawnego kodu, punktem startowym jest `#61afef`.
2. `Tab` / `Shift-Tab` przechodzi po klikalnych wierszach, `Enter` wybiera element, `Ctrl-t` zmienia składowe okno, a na sliderze `h/l` zmienia wartość.
3. Porównuj sekcje wariantów jasnych/ciemnych, hue, RGB, saturation, lightness i kolorów komplementarnych. Prompt ręczny powinien zawierać pełne `#RRGGBB`.
4. `q` lub `Esc` w Normal zamyka bez zastosowania. `Ctrl-s` albo przycisk Save zamyka UI i zastępuje na oryginalnym wierszu wszystkie dokładne wystąpienia sześciu cyfr starego koloru nowym kodem.
5. Save nie kopiuje do schowka. Po zastosowaniu sprawdź wiersz; w razie pomyłki użyj od razu `u`.

### Tutorial: Shades

1. Ustaw kursor na `#RRGGBB` i uruchom `:Shades`.
2. Przełączaj zakładki `Variants`, `Saturation` i `Hues`; wybierz układ 6 albo 12 kolumn i dopasuj intensywność.
3. Zastosowanie ma tę samą semantykę co Huefy: modyfikuje oryginalny wiersz, a nie globalną paletę czy schowek.

W tmux dosłowny `Ctrl-s` to `Ctrl-s Ctrl-s`. Stary help tej rewizji pokazuje nieaktualne API `require("minty.huefy").save_color()`; rzeczywista funkcja znajduje się w module `.api`, ale nie należy wywoływać jej poza aktywnym UI.

**Źródła przypiętej rewizji:** [help Minty](https://github.com/nvzone/minty/blob/aafc9e8e0afe6bf57580858a2849578d8d8db9e0/doc/minty.txt), [Huefy](https://github.com/nvzone/minty/tree/aafc9e8e0afe6bf57580858a2849578d8d8db9e0/lua/minty/huefy), [Shades](https://github.com/nvzone/minty/tree/aafc9e8e0afe6bf57580858a2849578d8d8db9e0/lua/minty/shades).

<a id="plugin-nvim-web-devicons"></a>
## `nvim-web-devicons`

**Rola:** dostarcza ikony według pełnej nazwy i rozszerzenia dla statusline, tabufline, nvim-tree i Telescope. Nie ma osobnego eksploratora ani codziennego launchera.

### Tutorial diagnostyczny

1. Otwórz kilka plików różnych typów i porównaj ikony w tabufline, drzewie i pickerze.
2. Wykonaj `:NvimWebDeviconsHiTest`; polecenie pojawia się po pierwszym setup, który zwykle wywołuje konsument. Na całkiem świeżym starcie użyj najpierw `:Lazy load nvim-web-devicons` i `:lua require("nvim-web-devicons").get_icon("init.lua", "lua")`.
3. Bufor testowy pokazuje glyph, nazwę kategorii, highlight i jego efektywną definicję; zamknij go przez `:bd`.
4. Kwadraty lub tofu oznaczają zwykle zły font. Ustaw Nerd Font co najmniej z linii 2.3. Nazwy plików są dopasowywane bez uwzględnienia wielkości liter, rozszerzenia z uwzględnieniem.

API override ikon jest przeznaczone dla konfiguracji i powinno być uruchomione przed pierwszym setup. Nie jest potrzebne do normalnego użycia.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-tree/nvim-web-devicons/blob/803353450c374192393f5387b6a0176d0972b848/README.md), [test highlightów](https://github.com/nvim-tree/nvim-web-devicons/blob/803353450c374192393f5387b6a0176d0972b848/lua/nvim-web-devicons/hi-test.lua).

<a id="plugin-plenary-nvim"></a>
## `plenary.nvim`

**Rola:** biblioteka procesów, ścieżek i asynchroniczności używana tutaj przez Telescope, Neogit, NvChad UI i Base46. Przypięty Diffview nie wymaga już Plenary w runtime.

Zwykły użytkownik nie otwiera Plenary. Dla autorów wtyczek dostępny jest test harness:

1. W razie potrzeby załaduj bibliotekę przez `:Lazy load plenary.nvim`, bo lokalna specyfikacja nie ma triggera `cmd`.
2. `:PlenaryBustedFile %` uruchamia bieżący plik testowy, a `:PlenaryBustedDirectory ścieżka` rekurencyjnie znajduje `*_spec.lua` i domyślnie uruchamia je równolegle.
3. Wynik pojawia się w popupie zamykanym `q`; headless zwraca kod 0 albo 1.
4. Testy to dowolny kod Lua i mogą zmieniać pliki lub uruchamiać procesy. Opcje directory są parsowane jako Lua, więc nie wklejaj niezaufanych argumentów.

`<Plug>PlenaryTestFile` istnieje, ale repo nie przypisuje mu klawisza. Pozostałe moduły `async`, `job`, `path`, `scandir`, `curl` i profiler są API deweloperskim.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-lua/plenary.nvim/blob/b9fd5226c2f76c951fc8ed5923d85e4de065e509/README.md), [help test harness](https://github.com/nvim-lua/plenary.nvim/blob/b9fd5226c2f76c951fc8ed5923d85e4de065e509/doc/plenary-test.txt).

<a id="plugin-nui-nvim"></a>
## `nui.nvim`

**Rola:** biblioteka komponentów UI używana przez CodeDiff, przede wszystkim `nui.tree`, `nui.line` i `nui.split`. Nie ma `setup()`, polecenia Ex, globalnych mapowań ani panelu do samodzielnego otwarcia.

**Jak sprawdzić działanie:** otwórz `<leader>gD` albo `<leader>gh`. Jeżeli explorer i historia CodeDiff renderują się poprawnie, NUI działa. Przy błędzie `module 'nui.tree' not found` sprawdź `:Lazy`, `:messages`, zgodność commita i wykonaj `:Lazy! restore nui.nvim`, a następnie restart.

Przykłady Popup, Input, Menu, Layout i Split z README są kodem dla autorów wtyczek. Ich `j/k/Tab/Enter/Esc` nie są globalnymi mapowaniami ani skrótami panelu CodeDiff.

**Źródła przypiętej rewizji:** [README i API komponentów](https://github.com/MunifTanjim/nui.nvim/blob/de740991c12411b663994b2860f1a4fd0937c130/README.md), [komponent Menu](https://github.com/MunifTanjim/nui.nvim/blob/de740991c12411b663994b2860f1a4fd0937c130/lua/nui/menu/init.lua).

<a id="plugin-nvim-nio"></a>
## `nvim-nio`

**Rola:** asynchroniczna biblioteka wymagana przez `nvim-dap-ui`. Nie ma konfiguracji użytkownika, poleceń, mapowań ani własnego interfejsu debuggera.

**Jak sprawdzić działanie:** uruchom dowolny trigger DAP i `<leader>du`. Poprawne otwarcie paneli jest testem NIO. Jeżeli dap-ui zgłasza brak `nio`, sprawdź zależność w `:Lazy`, `:messages`, wykonaj `:Lazy! restore nvim-nio` i zrestartuj Neovim.

`nio.run`, taski, eventy, future, queue, semaphore, async file/process/libuv/LSP/UI oraz test wrappery są **Opcjonalnym upstream API** dla autorów pluginów, nie osobnym workflow użytkownika.

**Źródła przypiętej rewizji:** [README](https://github.com/nvim-neotest/nvim-nio/blob/edcc181a875301dd21840189aa2f2f9ad69fc172/README.md), [help API](https://github.com/nvim-neotest/nvim-nio/blob/edcc181a875301dd21840189aa2f2f9ad69fc172/doc/nio.txt).
