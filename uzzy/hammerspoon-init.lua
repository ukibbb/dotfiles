-- hammerspoon-init.lua - Konfiguracja Hammerspoon dla uzzy
--
-- INSTALACJA:
--   Dodaj zawartość tego pliku do ~/.hammerspoon/init.lua
--   lub: require("dotfiles.uzzy.hammerspoon-init")
--
-- HOTKEY:
--   Cmd+Shift+U = Uruchom uzzy (tmux session manager)

local uzzyPath = os.getenv("HOME") .. "/.local/bin/uzzy"

local function launchUzzy()
    print("uzzy: Uruchamianie...")

    -- Sprawdź czy uzzy jest zainstalowany
    if hs.fs.attributes(uzzyPath) == nil then
        hs.alert.show("uzzy nie znaleziony!\nUruchom: make install", 2)
        print("BŁĄD: Nie znaleziono: " .. uzzyPath)
        return
    end

    -- Otwórz Ghostty z uzzy
    -- -e = execute command in new window
    local task = hs.task.new(
        "/usr/bin/open",
        function(exitCode, stdout, stderr)
            if exitCode == 0 then
                print("uzzy: Uruchomiono w Ghostty")
            else
                print("uzzy: Błąd - " .. tostring(stderr))
            end
        end,
        {"-a", "Ghostty", "--args", "-e", uzzyPath}
    )

    task:start()
    hs.alert.show("uzzy", 0.5)
end

-- Cmd+Shift+U = uzzy
hs.hotkey.bind({"cmd", "shift"}, "U", launchUzzy)
print("✓ uzzy hotkey zarejestrowany: Cmd+Shift+U")
