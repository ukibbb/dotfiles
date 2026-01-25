## 2. Interfejs — Panele

Lazygit ma 5 głównych paneli (przełączaj: `1-5` lub `h/l`):

| Panel | Numer | Co pokazuje |
|-------|-------|-------------|
| Status | 1 | Obecny branch, remote status, repo info |
| Files | 2 | Zmienione pliki (staged/unstaged) |
| Branches | 3 | Lokalne branche, remotes, tagi |
| Commits | 4 | Historia commitów |
| Stash | 5 | Stash entries |

### Widoki w panelu Branches (tabs: `[` / `]`)

- Local Branches
- Remotes
- Tags

### Widoki w panelu Commits (tabs: `[` / `]`)

- Commits
- Reflog

### Main Panel (prawy panel)

Pokazuje diff, podgląd pliku, commit details — zależy od kontekstu.

---

## 3. Nawigacja Globalna

| Klawisz | Działanie |
|---------|-----------|
| `h` / `l` | Przełącz panel (lewo/prawo) |
| `j` / `k` | Góra/dół w liście |
| `1`-`5` | Skocz do panelu |
| `[` / `]` | Poprzednia/następna zakładka w panelu |
| `,` / `.` | Poprzednia/następna strona |
| `<` / `>` | Scroll na górę/dół |
| `H` / `L` | Scroll lewo/prawo w main panel |
| `<pgup>` / `<pgdown>` | Scroll main panel |
| `{` / `}` | Zmień rozmiar diff context |
| `+` / `_` | Cycle screen mode (normal/half/full) |
| `/` | Szukaj w aktualnym widoku |
| `?` | Pokaż keybindings (help) |
| `q` | Zamknij / Wyjdź |
| `<Esc>` | Anuluj / Wróć |
| `@` | Command log options |
| `R` | Odśwież stan git |
| `:` | Wykonaj custom shell command |
| `<C-r>` | Przełącz na ostatnie repo |

---

## 4. Panel Files — Operacje na Plikach

### Staging

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Stage/unstage plik |
| `a` | Stage/unstage wszystkie pliki |
| `<Enter>` | Wejdź do staging view (linie/hunki) |
| `` ` `` | Toggle widok tree/flat |
| `-` / `=` | Collapse/Expand all (tree view) |

### Commity

| Klawisz | Działanie |
|---------|-----------|
| `c` | Commit (otwórz message input) |
| `C` | Commit z edytorem (pełny edytor) |
| `w` | Commit bez pre-commit hook |
| `A` | Amend ostatni commit (dodaj staged changes) |

### Discard

| Klawisz | Działanie |
|---------|-----------|
| `d` | Discard zmiany w pliku |
| `D` | Reset working tree (menu z opcjami) |

### Stash

| Klawisz | Działanie |
|---------|-----------|
| `s` | Stash (zachowaj zmiany) |
| `S` | Stash options (menu) |

### Inne

| Klawisz | Działanie |
|---------|-----------|
| `e` | Edytuj plik w edytorze |
| `o` | Otwórz plik domyślną aplikacją |
| `i` | Ignore/Exclude plik (.gitignore) |
| `<C-b>` | Filter by status (staged/unstaged/all) |
| `<C-f>` | Znajdź base commit dla fixup |

---

## 5. Staging View — Linie i Hunki

Wejdź przez `<Enter>` na pliku w Files panel.

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Stage/unstage zaznaczoną linię |
| `a` | Stage/unstage cały hunk |
| `v` | Toggle range select (zaznacz wiele linii) |
| `d` | Discard zmianę (linia/hunk) |
| `E` | Edytuj hunk ręcznie |
| `<Tab>` | Przełącz staged ↔ unstaged view |
| `<Left>` / `<Right>` | Poprzedni/następny hunk |
| `e` | Edytuj plik w edytorze |

---

## 6. Panel Branches — Branche

### Operacje na branchach

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Checkout branch |
| `n` | New branch (od obecnego) |
| `c` | Checkout by name (wpisz nazwę) |
| `-` | Checkout previous branch |
| `F` | Force checkout |
| `d` | Delete branch (menu z opcjami) |
| `R` | Rename branch |
| `<Enter>` | Pokaż commity brancha |

### Merge / Rebase

| Klawisz | Działanie |
|---------|-----------|
| `M` | Merge into checked out branch (menu) |
| `r` | Rebase checked out branch onto selected |
| `f` | Fast-forward branch to upstream |

### Remote

| Klawisz | Działanie |
|---------|-----------|
| `u` | Upstream options (set/unset) |
| `p` / `P` | Pull / Push |
| `o` | Create pull request |
| `O` | View PR options |
| `<C-y>` | Copy PR URL |

### Tags

| Klawisz | Działanie |
|---------|-----------|
| `T` | New tag na commit |

### Sorting

| Klawisz | Działanie |
|---------|-----------|
| `s` | Sort order (alphabetical, date, recency) |

### Worktrees

| Klawisz | Działanie |
|---------|-----------|
| `w` | Worktree options (create/switch) |

---

## 7. Panel Commits — Historia

### Nawigacja

| Klawisz | Działanie |
|---------|-----------|
| `<Enter>` | Pokaż pliki commita |
| `<C-o>` | Kopiuj commit hash |
| `<C-l>` | Log options (author, message, date) |
| `*` | Zaznacz commity obecnego brancha |
| `W` | View diffing options (porównaj commity) |

### Reword / Amend

| Klawisz | Działanie |
|---------|-----------|
| `r` | Reword commit message (inline) |
| `R` | Reword z edytorem |
| `A` | Amend commit (dodaj staged changes do starego commita) |
| `a` | Zmień commit attribute (author, etc.) |

### Interactive Rebase

| Klawisz | Działanie |
|---------|-----------|
| `i` | Start interactive rebase |
| `s` | Squash commit (połącz z poprzednim, zachowaj oba messages) |
| `f` | Fixup (połącz, odrzuć message tego commita) |
| `d` | Drop commit (usuń) |
| `e` | Edit commit (zatrzymaj rebase, edytuj) |
| `p` | Pick (zachowaj jak jest) |
| `<C-j>` / `<C-k>` | Move commit down/up |
| `m` | View merge/rebase options (continue/abort/skip) |

### Fixup Commits

| Klawisz | Działanie |
|---------|-----------|
| `F` (Shift+F) | Create fixup commit dla zaznaczonego commita |
| `S` (Shift+S) | Squash all fixup commits (autosquash) |

### Cherry-pick

| Klawisz | Działanie |
|---------|-----------|
| `C` (Shift+C) | Copy commit (cherry-pick start) |
| `V` (Shift+V) | Paste commit (cherry-pick apply) |

### Revert

| Klawisz | Działanie |
|---------|-----------|
| `t` | Revert commit (utwórz odwracający commit) |

### Bisect

| Klawisz | Działanie |
|---------|-----------|
| `b` | Bisect menu (mark good/bad, start/reset) |

### Custom Patch

| Klawisz | Działanie |
|---------|-----------|
| `<C-p>` | Custom patch options |

### Base Commit

| Klawisz | Działanie |
|---------|-----------|
| `B` (Shift+B) | Mark as base commit for rebase |

### New Branch

| Klawisz | Działanie |
|---------|-----------|
| `n` | New branch from commit |
| `N` | Move commits to new branch |

---

## 8. Commit Files — Pliki w Commicie

Wejdź przez `<Enter>` na commicie.

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Toggle plik w custom patch |
| `a` | Toggle all files w patch |
| `<Enter>` | Wejdź do pliku (podgląd diff/toggle lines) |
| `c` | Checkout plik (przywróć wersję z tego commita) |
| `d` | Remove plik (discard changes from commit) |
| `e` | Edytuj plik |
| `o` | Otwórz plik |
| `<C-o>` | Kopiuj path |

---

## 9. Panel Stash

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Apply stash (zachowaj w stash) |
| `g` | Pop stash (apply + usuń) |
| `d` | Drop stash (usuń bez apply) |
| `n` | New branch from stash |
| `r` | Rename stash |
| `<Enter>` | Pokaż pliki w stash entry |

---

## 10. Merge Conflicts

Lazygit automatycznie wykrywa konflikty i pokazuje panel rozwiązywania:

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Pick hunk (wybierz tę wersję) |
| `b` | Pick both (zachowaj obie wersje) |
| `<Left>` / `<Right>` | Poprzedni/następny konflikt |
| `z` | Undo last pick |
| `<Esc>` | Wróć do files |

Po rozwiązaniu: plik jest auto-staged (jeśli włączone `autoStageResolvedConflicts`).

---

## 11. Interactive Rebase — Szczegóły

### Workflow

1. W panelu Commits, naciśnij `i` na commicie od którego chcesz rebase
2. Lub naciśnij `e` na commicie by go edytować (auto-starts rebase)
3. Użyj `s`/`f`/`d`/`p` by zmienić akcje
4. Użyj `<C-j>`/`<C-k>` by przesuwać commity
5. Po zakończeniu: `m` → continue

### Akcje Rebase

| Akcja | Klawisz | Opis |
|-------|---------|------|
| Pick | `p` | Zachowaj commit jak jest |
| Squash | `s` | Połącz z poprzednim (zachowaj oba messages) |
| Fixup | `f` | Połącz z poprzednim (odrzuć ten message) |
| Drop | `d` | Usuń commit |
| Edit | `e` | Zatrzymaj rebase na tym commicie |
| Move Up | `<C-k>` | Przesuń commit wyżej |
| Move Down | `<C-j>` | Przesuń commit niżej |

### Amend Old Commits (bez explicit rebase)

1. Stage zmiany w Files panel
2. W Commits panel, naciśnij `A` (Shift+A) na starym commicie
3. Lazygit automatycznie wykona rebase w tle

---

## 12. Fixup Commits — Workflow

### Problem

Recenzent prosi o zmiany do konkretnego commita w PR.

### Rozwiązanie

1. Zrób zmiany i stage je
2. W Commits panel, znajdź commit do poprawy
3. Naciśnij `F` (Shift+F) — tworzy "fixup! Original message"
4. Opcjonalnie: użyj "amend!" dla zmiany message + code
5. Przed merge: zaznacz base commit, naciśnij `S` (Shift+S) — autosquash

### Szybkie znajdowanie base commita

W Files panel naciśnij `<C-f>` — lazygit znajdzie commit odpowiedni dla fixup.

---

## 13. Cherry-Pick

### Workflow

1. Przejdź do commita źródłowego
2. Naciśnij `C` (Shift+C) — kopiuj commit
3. Możesz zaznaczyć wiele commitów (range select `v`)
4. Przejdź do docelowego brancha
5. Naciśnij `V` (Shift+V) — paste (cherry-pick)

---

## 14. Bisect — Szukanie Błędnego Commita

### Workflow

1. W Commits panel, naciśnij `b` na commicie
2. Wybierz "mark as bad" (obecny jest zły) lub "mark as good" (ten był ok)
3. Lazygit automatycznie nawiguje do środkowego commita
4. Testuj i oznaczaj: `b` → good/bad
5. Po znalezieniu: lazygit wskazuje winny commit
6. `b` → reset bisect

---

## 15. Custom Patch — Zaawansowane

### Co to jest?

Pozwala wyciągnąć/przenieść konkretne zmiany z commitów.

### Workflow

1. W Commits panel, `<Enter>` na commicie
2. W Commit Files, `<Space>` aby toggle pliki do patcha
3. Lub `<Enter>` w plik i zaznacz konkretne linie
4. Naciśnij `<C-p>` — custom patch options:
   - Apply patch
   - Apply patch in reverse
   - Move patch to new commit
   - Move patch to selected commit
   - Extract patch into index

---

## 16. Diff / Porównywanie

### Porównywanie commitów

1. Na commicie naciśnij `W` (Shift+W) — "mark commit for diff"
2. Przejdź do drugiego commita — main panel pokazuje różnicę

### Diff options

| Klawisz | Działanie |
|---------|-----------|
| `W` | Mark/unmark for diff |
| `<C-e>` | View diffing options |
| `{` / `}` | Zwiększ/zmniejsz context size |
| `(` / `)` | Adjust rename similarity threshold |

---

## 17. Stacked Branches

### Koncept

Wiele branchy ułożonych jeden na drugim — np. refactor → backend → frontend.

### Wymagania

```bash
git config rebase.updateRefs true
```

### Workflow

1. Utwórz brancha `feature/refactor` od main
2. Commituj zmiany
3. Utwórz `feature/backend` od `feature/refactor`
4. Commituj
5. Utwórz `feature/frontend` od `feature/backend`

Rebase topowego brancha automatycznie aktualizuje wszystkie poniżej.

### Wizualizacja

- Cyan `*` (lub branch icon z nerd fonts) wskazuje head każdego brancha w stosie

---

## 18. Undo / Redo

| Klawisz | Działanie |
|---------|-----------|
| `z` | Undo |
| `<C-z>` (lub `Z`) | Redo |

### Co można cofnąć

- Checkout branch
- Commit
- Rebase
- Merge
- Cherry-pick
- Drop commit
- Revert

### Czego NIE można cofnąć

- Zmiany w working tree (unstaged)
- Stash operations
- Push to remote
- Tworzenie branchy
- Operacje w trakcie rebase (użyj `m` → abort)

### Jak działa

Bazuje na git reflog — lazygit śledzi swoje akcje i potrafi je odwrócić nawet po restarcie.

---

## 19. Wyszukiwanie i Filtrowanie

| Klawisz | Działanie |
|---------|-----------|
| `/` | Search w aktualnym panelu |
| `<Enter>` | Potwierdź search |
| `n` / `N` | Następny/poprzedni wynik |
| `<Esc>` | Zamknij search |
| `<C-s>` | Filter options |

### Filter modes

- `substring` — dokładne dopasowanie fragmentu
- `fuzzy` — fuzzy matching

---

## 20. Range Select

| Klawisz | Działanie |
|---------|-----------|
| `v` | Toggle range select mode |
| `j` / `k` | Rozszerzaj zaznaczenie |

Działa w:
- Files (stage/unstage wiele)
- Commits (squash/drop wiele, cherry-pick wiele)
- Staging view (stage wiele linii)

---

## 21. Push / Pull / Fetch

| Klawisz | Działanie |
|---------|-----------|
| `P` (Shift+P) | Push |
| `p` | Pull |
| `f` (na branchu) | Fast-forward |

### Push options (po `P`)

- Push to current upstream
- Push to specific remote
- Force push
- Force push with lease

---

## 22. Remote Operations

W zakładce Remotes (panel Branches → `]`):

| Klawisz | Działanie |
|---------|-----------|
| `<Enter>` | Pokaż remote branches |
| `n` | Add new remote |
| `d` | Remove remote |
| `e` | Edit remote |
| `f` | Fetch from remote |

---

## 23. Submodules

W zakładce Submodules:

| Klawisz | Działanie |
|---------|-----------|
| `<Space>` | Enter submodule |
| `n` | Add submodule |
| `d` | Remove submodule |
| `u` | Update submodule |
| `e` | Update URL |
| `i` | Init submodule |
| `b` | Bulk init/update |

---

## 24. Konfiguracja — Szczegóły

Lokalizacja: `~/.config/lazygit/config.yml`

Otwórz z lazygit: `e` w Status panel.

### GUI

```yaml
gui:
  scrollHeight: 2
  scrollPastBottom: true
  mouseEvents: true
  sidePanelWidth: 0.3333
  mainPanelSplitMode: "flexible"  # horizontal|vertical|flexible
  showFileTree: true
  showListFooter: true
  showCommandLog: true
  showBottomLine: true
  border: "rounded"  # rounded|single|double|hidden|bold
  nerdFontsVersion: "3"  # "2"|"3"|""
  filterMode: "substring"  # substring|fuzzy
  screenMode: "normal"  # normal|half|full
  statusPanelView: "dashboard"  # dashboard|allBranchesLog
  language: "auto"
  timeFormat: "02 Jan 06"
  tabWidth: 4
```

### Theme

```yaml
gui:
  theme:
    activeBorderColor: ["#fabd2f", "bold"]
    inactiveBorderColor: ["#665c54"]
    optionsTextColor: ["#83a598"]
    selectedLineBgColor: ["#3c3836"]
    cherryPickedCommitBgColor: ["#689d6a"]
    cherryPickedCommitFgColor: ["#282828"]
    unstagedChangesColor: ["#fb4934"]
    defaultFgColor: ["#ebdbb2"]
    searchingActiveBorderColor: ["#fe8019"]
```

Dostępne kolory: hex, named (red, green, blue, etc.), lub terminal color numbers.

### Author Colors

```yaml
gui:
  authorColors:
    "John Smith": "#ff0000"
    "*": "#00ff00"  # default dla wszystkich
```

### Branch Color Patterns

```yaml
gui:
  branchColorPatterns:
    "feature/*": "#00ff00"
    "bugfix/*": "#ff0000"
    "hotfix/*": "#ff6600"
```

### Git Settings

```yaml
git:
  autoFetch: true
  autoRefresh: true
  fetchAll: true
  mainBranches: [master, main, develop]
  autoStageResolvedConflicts: true
  disableForcePushing: false
  overrideGpg: false

  commit:
    signOff: false
    autoWrapCommitMessage: true
    autoWrapWidth: 72

  merging:
    manualCommit: false
    args: ""

  log:
    order: "topo-order"  # date-order|topo-order|default
    showGraph: "always"  # always|never|when-maximised

  diffContextSize: 3
  renameSimilarityThreshold: 50
  skipHookPrefix: "WIP"

  branchPrefix: ""  # np. "feature/" — auto-prefix przy tworzeniu

  autoForwardBranches: "onlyMainBranches"  # none|onlyMainBranches|allBranches
```

### OS — Edytor

```yaml
os:
  editPreset: "nvim"  # nvim|vim|emacs|nano|vscode|sublime|...
  # lub custom:
  edit: 'nvim {{filename}}'
  editAtLine: 'nvim +{{line}} {{filename}}'
  open: 'open {{filename}}'
```

### Inne

```yaml
confirmOnQuit: false
quitOnTopLevelReturn: false
promptToReturnFromSubprocess: true
notARepository: "prompt"  # prompt|create|skip|quit

update:
  method: "prompt"  # prompt|background|never

refresher:
  refreshInterval: 10  # sekundy
  fetchInterval: 60    # sekundy
```

---

## 25. Custom Pagers (Diff Tools)

### Delta

```yaml
git:
  pagers:
    - pager: delta --dark --paging=never
```

### Delta z hyperlinks (kliknij → edytor)

```yaml
git:
  pagers:
    - pager: >-
        delta --dark --paging=never --line-numbers --hyperlinks
        --hyperlinks-file-link-format="lazygit-edit://{path}:{line}"
```

### Diff-so-fancy

```yaml
git:
  pagers:
    - pager: diff-so-fancy
```

### Difftastic (structural diff)

```yaml
git:
  pagers:
    - externalDiffCommand: difft --color=always
```

### Przełączanie pagerów

Naciśnij `|` w lazygit aby cycleować między skonfigurowanymi pagerami.

---

## 26. Custom Commands

### Struktura

```yaml
customCommands:
  - key: "<C-a>"
    context: "files"
    command: "git add -A"
    description: "Stage all files"
    loadingText: "Staging..."
```

### Contexts

- `global` — wszędzie
- `status`, `files`, `localBranches`, `remotes`, `remoteBranches`
- `tags`, `commits`, `reflogCommits`, `stash`
- `subCommits`, `commitFiles`, `worktrees`, `submodules`

### Prompts

```yaml
customCommands:
  - key: "C"
    context: "localBranches"
    description: "Checkout new branch with prefix"
    prompts:
      - type: "input"
        title: "Branch name:"
        key: "BranchName"
        initialValue: ""
    command: "git checkout -b feature/{{.Form.BranchName}}"
```

### Prompt Types

| Type | Opis |
|------|------|
| `input` | Pole tekstowe |
| `confirm` | Tak/Nie dialog |
| `menu` | Lista opcji do wyboru |
| `menuFromCommand` | Dynamiczne menu z output komendy |

### Template Variables

```
{{.SelectedCommit.Hash}}
{{.SelectedCommit.Subject}}
{{.SelectedLocalBranch.Name}}
{{.SelectedFile.Name}}
{{.SelectedRemote.Name}}
{{.SelectedTag.Name}}
{{.SelectedStashEntry.Index}}
{{.CheckedOutBranch.Name}}
{{.Form.KeyName}}
```

### Output Options

| Wartość | Opis |
|---------|------|
| `none` | Ignoruj output |
| `terminal` | Wstrzymaj lazygit, uruchom interaktywnie |
| `log` | Pokaż w command log |
| `logWithPty` | Log z kolorami (pseudo-terminal) |
| `popup` | Pokaż w popup window |

### Przykłady

```yaml
customCommands:
  # Conventional commit
  - key: "C"
    context: "files"
    description: "Conventional commit"
    prompts:
      - type: "menu"
        title: "Type:"
        key: "Type"
        options:
          - value: "feat"
            name: "Feature"
          - value: "fix"
            name: "Bug Fix"
          - value: "refactor"
            name: "Refactor"
          - value: "docs"
            name: "Documentation"
      - type: "input"
        title: "Scope (optional):"
        key: "Scope"
      - type: "input"
        title: "Message:"
        key: "Message"
    command: >-
      git commit -m "{{.Form.Type}}{{if .Form.Scope}}({{.Form.Scope}}){{end}}: {{.Form.Message}}"

  # Force push with lease
  - key: "P"
    context: "global"
    command: "git push --force-with-lease"
    description: "Force push with lease"
    prompts:
      - type: "confirm"
        title: "Force push?"
        body: "Are you sure you want to force push?"

  # Open in GitHub
  - key: "O"
    context: "commits"
    command: "open https://github.com/user/repo/commit/{{.SelectedCommit.Hash}}"
    description: "Open commit on GitHub"
```

---

## 27. Worktrees

### Co to jest?

Git worktrees pozwalają mieć wiele checkout'ów tego samego repo jednocześnie — każdy w osobnym katalogu.

### Keybindings (w Branches panel)

| Klawisz | Działanie |
|---------|-----------|
| `w` | Worktree options |

### Operacje

- Create worktree z brancha
- Switch do innego worktree
- Delete worktree

### Zastosowanie

- Pracuj na feature branch i jednocześnie sprawdź main
- Code review innego brancha bez stash/switch

---

## 28. Commit Graph

Lazygit wyświetla git graph z kolorowymi liniami w panelu Commits.

| Klawisz | Działanie |
|---------|-----------|
| `+` / `_` | Cycle screen mode (powiększ graph) |
| `<C-l>` | Log options (zmień co wyświetla) |

### Konfiguracja

```yaml
git:
  log:
    showGraph: "always"  # always|never|when-maximised
    order: "topo-order"  # topo-order|date-order|default
```

---

## 29. Keybinding Overrides

Zmień domyślne keybindings w config:

```yaml
keybinding:
  universal:
    quit: "q"
    return: "<Esc>"
    scrollUpMain: "<pgup>"
    scrollDownMain: "<pgdown>"
    prevItem: "k"
    nextItem: "j"
    prevTab: "["
    nextTab: "]"
    gotoTop: "<"
    gotoBottom: ">"
    undo: "z"
    redo: "<C-z>"

  files:
    commitChanges: "c"
    commitChangesWithEditor: "C"
    amendLastCommit: "A"

  branches:
    createPullRequest: "o"
    checkoutBranchByName: "c"

  commits:
    squashDown: "s"
    pickCommit: "p"
    cherryPickCopy: "C"
    pasteCommits: "V"
    moveDownCommit: "<C-j>"
    moveUpCommit: "<C-k>"
```

---

## 30. Workflow — Typowe Scenariusze

### Szybki commit
```
j/k wybierz pliki → Space stage → c → wpisz message → Enter
```

### Stage konkretnych linii
```
Enter na pliku → v (range) → zaznacz linie → Space stage → Esc → c commit
```

### Interactive rebase (squash commits)
```
Panel Commits → i na starym commicie → s/f na kolejnych → m → continue
```

### Amend starego commita
```
Stage zmiany → Panel Commits → A (Shift+A) na commicie
```

### Rozwiąż konflikty
```
Panel Files → Enter na konflikcie → Space pick → Left/Right nawiguj → Esc
```

### Cherry-pick między branchami
```
Panel Commits → C (copy) → Panel Branches → checkout target → Panel Commits → V (paste)
```

### Fixup workflow (code review)
```
Zrób poprawki → stage → Panel Commits → F (Shift+F) na commicie → S (Shift+S) autosquash
```

### Rebase na main
```
Panel Branches → zaznacz main → r (rebase checked-out onto selected)
```

### Stash i przywróć
```
Panel Files → s (stash) → ... pracuj ... → Panel Stash → Space (apply) lub g (pop)
```

### Bisect
```
Panel Commits → b → mark as bad → nawiguj do dobrego → b → good → repeat → found!
```

### Porównaj commity
```
W na commicie A → przejdź do B → main panel pokazuje diff
```

---

## 31. Najważniejsze Komendy - Ściągawka

| Akcja | Klawisz |
|-------|---------|
| **Help** | `?` |
| **Stage file** | `Space` |
| **Stage all** | `a` |
| **Stage lines** | `Enter` → `Space` |
| **Commit** | `c` |
| **Amend** | `A` (na starym commicie) |
| **Push** | `P` |
| **Pull** | `p` |
| **Checkout branch** | `Space` (w Branches) |
| **New branch** | `n` |
| **Merge** | `M` |
| **Rebase** | `r` |
| **Squash** | `s` |
| **Fixup** | `f` |
| **Drop commit** | `d` |
| **Move commit** | `Ctrl-j` / `Ctrl-k` |
| **Cherry-pick copy** | `C` (Shift) |
| **Cherry-pick paste** | `V` (Shift) |
| **Stash** | `s` (w Files) |
| **Undo** | `z` |
| **Redo** | `Ctrl-z` |
| **Search** | `/` |
| **Screen mode** | `+` / `_` |
| **Shell command** | `:` |
| **Quit** | `q` |

---

## 32. Troubleshooting

### Lazygit nie otwiera edytora
```yaml
# W config.yml:
os:
  editPreset: "nvim"
```

### Diff za mały / za duży
- `{` / `}` — zmień context size
- `+` / `_` — zmień screen mode

### Force push nie działa
```yaml
git:
  disableForcePushing: false  # sprawdź tę opcję
```

### Chcę zobaczyć config path
```bash
lazygit --print-config-dir
```

### Reset konfiguracji
```bash
rm ~/.config/lazygit/config.yml
# lazygit utworzy nowy przy starcie
```

### Integracja z Neovim

Użyj pluginu `kdheepak/lazygit.nvim` lub otwórz w terminalu:
```lua
vim.keymap.set("n", "<leader>lg", "<cmd>!lazygit<cr>")
```

---

## Dodatkowe Zasoby

- **GitHub**: https://github.com/jesseduffield/lazygit
- **Keybindings docs**: https://github.com/jesseduffield/lazygit/blob/master/docs/keybindings/Keybindings_en.md
- **Config docs**: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
- **Custom commands**: https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_Command_Keybindings.md
- **Twoja konfiguracja**: `~/.config/lazygit/config.yml`
