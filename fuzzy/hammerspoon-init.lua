-- =============================================================================
-- hammerspoon-init.lua - Konfiguracja Hammerspoon dla Project Launcher
-- =============================================================================
-- Ten plik zawiera konfigurację Hammerspoon do uruchamiania Project Launcher
-- za pomocą globalnego skrótu klawiszowego (Cmd+Shift+P).
--
-- INSTALACJA:
--   1. Zainstaluj Hammerspoon: https://www.hammerspoon.org/
--   2. Skopiuj zawartość tego pliku do ~/.hammerspoon/init.lua
--      LUB dodaj require() na końcu istniejącego pliku
--   3. Uruchom Hammerspoon (ikona w menu bar)
--   4. Reload config (Cmd+Ctrl+R lub przez menu Hammerspoon)
--
-- WYMAGANIA:
--   - Hammerspoon musi być uruchomiony w tle (daemon)
--   - Hammerspoon musi mieć uprawnienia Accessibility w System Preferences
--
-- UŻYCIE:
--   Naciśnij Cmd+Shift+P w dowolnym miejscu w systemie
-- =============================================================================

-- =============================================================================
-- KONFIGURACJA - Ścieżki i ustawienia
-- =============================================================================

-- Ścieżka do skryptu launcher
-- os.getenv("HOME") = pobierz ścieżkę do katalogu domowego użytkownika ($HOME)
-- .. = operator konkatenacji stringów w Lua
local launcherPath = os.getenv("HOME") .. "/Desktop/dotfiles/fuzzy/launcher"

-- Skrót klawiszowy do uruchomienia launcher
-- Modyfikatory: "cmd" (Command), "shift"
-- Klawisz: "P"
-- To będzie: Cmd+Shift+P
local hotkey_mods = {"cmd", "shift"}  -- Tablica z modyfikatorami
local hotkey_key = "P"                -- Klawisz do naciśnięcia

-- =============================================================================
-- FUNKCJA: launchProjectLauncher
-- =============================================================================
-- Funkcja wywoływana gdy użytkownik naciśnie skrót klawiszowy.
-- Uruchamia skrypt launcher w tle używając hs.task.
-- =============================================================================
local function launchProjectLauncher()
    -- Wypisz debug message do Hammerspoon console
    -- hs.console.printStyledtext = wypisz do konsoli Hammerspoon
    print("Project Launcher: Uruchamianie...")

    -- Sprawdź czy plik launcher istnieje
    -- hs.fs.attributes = zwraca atrybuty pliku (nil jeśli nie istnieje)
    if hs.fs.attributes(launcherPath) == nil then
        -- Plik NIE istnieje - wyświetl alert
        -- hs.alert.show = wyświetl natywny alert macOS (toast notification)
        hs.alert.show("❌ Błąd: launcher nie znaleziony!\n" .. launcherPath)
        print("BŁĄD: Nie znaleziono pliku: " .. launcherPath)
        return  -- Zakończ funkcję
    end

    -- Utwórz i uruchom task (proces w tle)
    -- hs.task.new = tworzy nowy task (proces)
    -- Parametry:
    --   1. launcherPath = ścieżka do programu do uruchomienia
    --   2. function(exitCode, stdout, stderr) = callback wywoływany gdy task się zakończy
    --   3. nil = tablica z argumentami (brak argumentów w tym przypadku)
    local task = hs.task.new(
        launcherPath,  -- Komenda do uruchomienia

        -- Callback function - wywoływana gdy task się zakończy
        function(exitCode, stdout, stderr)
            -- exitCode = kod wyjścia procesu (0 = sukces, != 0 = błąd)
            -- stdout = output z procesu (standard output)
            -- stderr = błędy z procesu (standard error)

            -- Sprawdź czy task zakończył się sukcesem
            if exitCode == 0 then
                -- Sukces (exit code 0)
                print("Project Launcher: Zakończono pomyślnie")
            else
                -- Błąd (exit code != 0)
                print("Project Launcher: Zakończono z błędem (kod: " .. tostring(exitCode) .. ")")

                -- Jeśli są jakieś błędy w stderr, wypisz je
                if stderr and stderr ~= "" then
                    print("STDERR: " .. stderr)
                end
            end
        end,

        nil  -- Brak dodatkowych argumentów dla launcher
    )

    -- Uruchom task
    -- :start() = metoda uruchamiająca task w tle
    task:start()

    -- Pokaż krótki alert że launcher został uruchomiony
    -- hs.alert.show(message, duration) = pokaż alert przez X sekund
    hs.alert.show("🚀 Project Launcher", 1)  -- Pokaż przez 1 sekundę
end

-- =============================================================================
-- REJESTRACJA HOTKEY - Bind skrótu klawiszowego
-- =============================================================================

-- Zarejestruj globalny skrót klawiszowy
-- hs.hotkey.bind = tworzy globalny hotkey binding
-- Parametry:
--   1. hotkey_mods = tablica z modyfikatorami (cmd, shift, etc.)
--   2. hotkey_key = klawisz do naciśnięcia
--   3. launchProjectLauncher = funkcja do wywołania
hs.hotkey.bind(hotkey_mods, hotkey_key, launchProjectLauncher)

-- Wypisz potwierdzenie do konsoli Hammerspoon
-- tostring = konwertuje wartość na string
-- table.concat = łączy elementy tablicy w string (separator = "+")
print("✓ Project Launcher hotkey zarejestrowany: " .. table.concat(hotkey_mods, "+") .. "+" .. hotkey_key)

-- =============================================================================
-- OPCJONALNE ROZSZERZENIA
-- =============================================================================

-- Możesz dodać dodatkowe hotkey dla różnych trybów:
--
-- Przykład: Cmd+Shift+N = bezpośrednio tryb "tmux-nvim"
-- hs.hotkey.bind({"cmd", "shift"}, "N", function()
--     local task = hs.task.new(launcherPath, nil, {"--mode", "tmux-nvim"})
--     task:start()
--     hs.alert.show("🚀 Launcher: Tmux + Neovim", 1)
-- end)

-- Przykład: Cmd+Shift+T = tylko terminal
-- hs.hotkey.bind({"cmd", "shift"}, "T", function()
--     local task = hs.task.new(launcherPath, nil, {"--mode", "terminal-only"})
--     task:start()
--     hs.alert.show("🚀 Launcher: Terminal", 1)
-- end)

-- =============================================================================
-- NOTYFIKACJA O ZAŁADOWANIU
-- =============================================================================

-- Wyświetl alert że konfiguracja została załadowana
-- Przydatne przy debugowaniu
hs.alert.show("✓ Project Launcher config loaded", 1.5)
