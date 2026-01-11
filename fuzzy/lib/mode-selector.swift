#!/usr/bin/env swift
// =============================================================================
// mode-selector.swift - Native macOS GUI dla wyboru trybu uruchomienia projektu
// =============================================================================
// Ten program wyświetla natywne okno dialogowe macOS z listą dostępnych
// trybów uruchomienia projektu. Użytkownik wybiera tryb, a program zwraca
// identyfikator wybranego trybu przez stdout.
//
// Kompilacja: swiftc mode-selector.swift -o mode-selector
// Użycie: ./mode-selector [project_path]
//
// Output (stdout): Identyfikator wybranego trybu (np. "tmux-nvim-claude")
// Exit code: 0 = sukces, 1 = anulowano lub błąd
// =============================================================================

// Importuj framework AppKit (UI dla macOS)
import AppKit

// =============================================================================
// ENUM: LaunchMode - Definicja dostępnych trybów uruchomienia
// =============================================================================
// Enum reprezentujący wszystkie dostępne tryby uruchomienia projektu.
// Każdy tryb ma:
//   - rawValue: identyfikator zwracany przez program (String)
//   - title: nazwa wyświetlana w GUI
//   - description: opis pokazywany użytkownikowi
// =============================================================================
enum LaunchMode: String, CaseIterable {
    // Terminal only - tylko Ghostty bez dodatkowych narzędzi
    case terminalOnly = "terminal-only"

    // Terminal + Tmux - terminal z uruchomionym tmux (bez sesji)
    case terminalTmux = "terminal-tmux"

    // Tmux Session - nazwana sesja tmux z możliwością reattach
    case tmuxSession = "tmux-session"

    // Tmux + Neovim - sesja tmux z automatycznie uruchomionym neovim
    case tmuxNvim = "tmux-nvim"

    // Tmux + Neovim + Claude Code - sesja z neovim i claude w osobnych oknach
    case tmuxNvimClaude = "tmux-nvim-claude"

    // Właściwość obliczana: tytuł wyświetlany w GUI
    var title: String {
        switch self {
        case .terminalOnly:
            return "Terminal (Ghostty)"
        case .terminalTmux:
            return "Terminal + Tmux"
        case .tmuxSession:
            return "Tmux Session"
        case .tmuxNvim:
            return "Tmux + Neovim"
        case .tmuxNvimClaude:
            return "Tmux + Neovim + Claude Code"
        }
    }

    // Właściwość obliczana: opis wyświetlany w GUI
    var description: String {
        switch self {
        case .terminalOnly:
            return "Tylko terminal Ghostty w wybranym katalogu"
        case .terminalTmux:
            return "Terminal z uruchomionym tmux (bez nazwanej sesji)"
        case .tmuxSession:
            return "Nazwana sesja tmux z możliwością ponownego podłączenia"
        case .tmuxNvim:
            return "Sesja tmux z automatycznie uruchomionym Neovim"
        case .tmuxNvimClaude:
            return "Sesja tmux: okno z Neovim + okno z Claude Code"
        }
    }
}

// =============================================================================
// CLASS: ModeSelectorWindow - Główne okno aplikacji
// =============================================================================
// Klasa reprezentująca okno dialogowe do wyboru trybu.
// Dziedziczy po NSObject aby móc być delegatem aplikacji.
// =============================================================================
class ModeSelectorWindow: NSObject, NSApplicationDelegate {
    // Wybrana opcja (nil jeśli użytkownik anulował)
    var selectedMode: LaunchMode? = nil

    // Główne okno aplikacji
    var window: NSWindow!

    // Ścieżka do projektu (przekazana jako argument)
    var projectPath: String = ""

    // =============================================================================
    // METODA: applicationDidFinishLaunching
    // =============================================================================
    // Wywoływana automatycznie gdy aplikacja się uruchomi.
    // Tutaj tworzymy i wyświetlamy okno GUI.
    // =============================================================================
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Utwórz główne okno aplikacji
        createWindow()

        // Pokaż okno na wierzchu (na pierwszym planie)
        NSApp.activate(ignoringOtherApps: true)
    }

    // =============================================================================
    // METODA: createWindow
    // =============================================================================
    // Tworzy i konfiguruje główne okno aplikacji z przyciskami wyboru trybu.
    // =============================================================================
    func createWindow() {
        // Zdefiniuj rozmiar okna (szerokość x wysokość w pikselach)
        let windowWidth: CGFloat = 500
        let windowHeight: CGFloat = 400

        // Pobierz rozmiar głównego ekranu
        let screenFrame = NSScreen.main?.frame ?? .zero

        // Oblicz pozycję okna aby wycentrować je na ekranie
        // (screen width - window width) / 2 = pozycja X dla wycentrowania
        let windowX = (screenFrame.width - windowWidth) / 2
        let windowY = (screenFrame.height - windowHeight) / 2

        // Utwórz prostokąt definiujący pozycję i rozmiar okna
        let windowRect = NSRect(
            x: windowX,
            y: windowY,
            width: windowWidth,
            height: windowHeight
        )

        // Utwórz okno z następującymi stylami:
        // - titled: okno ma pasek tytułowy
        // - closable: okno ma przycisk zamknięcia
        // - miniaturizable: okno może być zminimalizowane
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,  // Buforowany rendering (standardowy)
            defer: false         // Nie odkładaj utworzenia okna
        )

        // Ustaw tytuł okna
        window.title = "Project Launcher - Wybierz tryb"

        // Wycentruj okno na ekranie
        window.center()

        // Utwórz widok zawartości (content view) - główny kontener dla elementów UI
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))

        // Ustaw kolor tła na standardowy kolor tła okna macOS
        contentView.wantsLayer = true  // Włącz warstwy (layers) dla widoku
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // =============================================================================
        // Nagłówek - tytuł i ścieżka projektu
        // =============================================================================

        // Utwórz etykietę (label) z tytułem
        let titleLabel = NSTextField(labelWithString: "Wybierz sposób uruchomienia projektu:")
        // Ustaw czcionkę na pogrubioną, rozmiar 14
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        // Ustaw pozycję i rozmiar etykiety (X, Y, szerokość, wysokość)
        titleLabel.frame = NSRect(x: 20, y: windowHeight - 40, width: windowWidth - 40, height: 20)
        // Dodaj etykietę do widoku
        contentView.addSubview(titleLabel)

        // Utwórz etykietę z ścieżką do projektu (jeśli została podana)
        if !projectPath.isEmpty {
            let pathLabel = NSTextField(labelWithString: "Projekt: \(projectPath)")
            pathLabel.font = NSFont.systemFont(ofSize: 11)  // Mniejsza czcionka
            pathLabel.textColor = .secondaryLabelColor      // Szary kolor tekstu
            pathLabel.frame = NSRect(x: 20, y: windowHeight - 65, width: windowWidth - 40, height: 16)
            contentView.addSubview(pathLabel)
        }

        // =============================================================================
        // Przyciski - dla każdego trybu uruchomienia
        // =============================================================================

        // Początkowa pozycja Y dla pierwszego przycisku
        var currentY: CGFloat = windowHeight - 100

        // Wysokość pojedynczego przycisku
        let buttonHeight: CGFloat = 50

        // Odstęp między przyciskami
        let buttonSpacing: CGFloat = 10

        // Dla każdego dostępnego trybu w LaunchMode...
        for mode in LaunchMode.allCases {
            // Utwórz kontener (box) dla przycisku - zawiera tytuł i opis
            let buttonBox = NSBox(frame: NSRect(
                x: 20,
                y: currentY,
                width: windowWidth - 40,
                height: buttonHeight
            ))

            // Ustaw styl boxa na custom (bez ramki)
            buttonBox.boxType = .custom
            // Zaokrąglone rogi o promieniu 8 pikseli
            buttonBox.cornerRadius = 8
            // Kolor ramki - jasny szary
            buttonBox.borderColor = NSColor.separatorColor
            // Szerokość ramki - 1 piksel
            buttonBox.borderWidth = 1
            // Kolor tła - jasny kolor (kontrolny)
            buttonBox.fillColor = NSColor.controlBackgroundColor

            // Utwórz przycisk (niewidoczny, tylko do kliknięcia)
            let button = NSButton(frame: buttonBox.bounds)
            // Ustaw styl na momentary push in (przycisk momentalny)
            button.setButtonType(.momentaryPushIn)
            // Usunięcie ramki - przycisk będzie przezroczysty
            button.isBordered = false
            // Ustaw tytuł przycisku (pusty, bo używamy własnego layoutu)
            button.title = ""
            // Ustaw target (obiekt który obsłuży kliknięcie) na self
            button.target = self
            // Ustaw akcję która zostanie wywołana po kliknięciu
            button.action = #selector(modeSelected(_:))
            // Ustaw tag (identyfikator) przycisku na indeks trybu w enum
            // Dzięki temu w modeSelected wiemy który tryb został wybrany
            button.tag = LaunchMode.allCases.firstIndex(of: mode) ?? 0

            // Dodaj przycisk do boxa
            buttonBox.addSubview(button)

            // Utwórz etykietę z tytułem trybu
            let modeTitle = NSTextField(labelWithString: mode.title)
            modeTitle.font = NSFont.boldSystemFont(ofSize: 13)  // Pogrubiona czcionka
            modeTitle.isBezeled = false        // Bez ramki
            modeTitle.isEditable = false       // Nie można edytować
            modeTitle.drawsBackground = false  // Przezroczyste tło
            // Pozycja: 10px od lewej, 28px od dołu boxa
            modeTitle.frame = NSRect(x: 10, y: 28, width: buttonBox.bounds.width - 20, height: 16)
            buttonBox.addSubview(modeTitle)

            // Utwórz etykietę z opisem trybu
            let modeDesc = NSTextField(labelWithString: mode.description)
            modeDesc.font = NSFont.systemFont(ofSize: 11)   // Mniejsza czcionka
            modeDesc.textColor = .secondaryLabelColor       // Szary kolor
            modeDesc.isBezeled = false
            modeDesc.isEditable = false
            modeDesc.drawsBackground = false
            // Pozycja: 10px od lewej, 10px od dołu boxa
            modeDesc.frame = NSRect(x: 10, y: 10, width: buttonBox.bounds.width - 20, height: 14)
            buttonBox.addSubview(modeDesc)

            // Dodaj box do głównego widoku
            contentView.addSubview(buttonBox)

            // Przesuń pozycję Y w dół dla następnego przycisku
            // currentY -= (wysokość przycisku + odstęp)
            currentY -= (buttonHeight + buttonSpacing)
        }

        // =============================================================================
        // Przycisk Cancel - na dole okna
        // =============================================================================

        // Utwórz przycisk "Anuluj"
        let cancelButton = NSButton(frame: NSRect(
            x: windowWidth - 100,  // 100px szerokości, wyrównany do prawej
            y: 20,                  // 20px od dołu
            width: 80,
            height: 32
        ))
        // Ustaw tytuł przycisku
        cancelButton.title = "Anuluj"
        // Ustaw styl przycisku na standardowy (rounded)
        cancelButton.bezelStyle = .rounded
        // Ustaw akcję - wywołaj cancelSelection gdy kliknięty
        cancelButton.target = self
        cancelButton.action = #selector(cancelSelection)
        // Dodaj przycisk do widoku
        contentView.addSubview(cancelButton)

        // Ustaw utworzony widok jako content view okna
        window.contentView = contentView

        // Pokaż okno na ekranie
        window.makeKeyAndOrderFront(nil)
    }

    // =============================================================================
    // METODA: modeSelected
    // =============================================================================
    // Wywoływana gdy użytkownik kliknie na jeden z przycisków trybu.
    // Zapisuje wybrany tryb i zamyka aplikację.
    //
    // Parametry:
    //   sender: Przycisk który został kliknięty (NSButton)
    // =============================================================================
    @objc func modeSelected(_ sender: NSButton) {
        // Pobierz tag przycisku (indeks w enum LaunchMode)
        let index = sender.tag

        // Pobierz wszystkie dostępne tryby
        let allModes = LaunchMode.allCases

        // Sprawdź czy indeks jest prawidłowy
        guard index < allModes.count else {
            // Nieprawidłowy indeks - zakończ aplikację z kodem błędu
            NSApp.terminate(nil)
            return
        }

        // Zapisz wybrany tryb używając indeksu
        selectedMode = allModes[index]

        // Wypisz identyfikator wybranego trybu na stdout
        // To będzie odczytane przez skrypt launcher
        print(selectedMode!.rawValue)

        // Zakończ aplikację z kodem sukcesu (0)
        exit(0)
    }

    // =============================================================================
    // METODA: cancelSelection
    // =============================================================================
    // Wywoływana gdy użytkownik kliknie przycisk "Anuluj" lub zamknie okno.
    // Kończy aplikację z kodem błędu (1).
    // =============================================================================
    @objc func cancelSelection() {
        // Zakończ aplikację z kodem błędu (1)
        // Launcher skrypt zrozumie że użytkownik anulował wybór
        exit(1)
    }

    // =============================================================================
    // METODA: applicationShouldTerminateAfterLastWindowClosed
    // =============================================================================
    // Wywoływana gdy ostatnie okno aplikacji zostanie zamknięte.
    // Zwracamy true aby aplikacja zakończyła się automatycznie.
    // =============================================================================
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // true = zakończ aplikację gdy okno zostanie zamknięte
        return true
    }
}

// =============================================================================
// MAIN - Punkt wejścia programu
// =============================================================================

// Utwórz instancję aplikacji NSApplication
let app = NSApplication.shared

// Utwórz instancję naszego delegata (ModeSelectorWindow)
let delegate = ModeSelectorWindow()

// Sprawdź czy został przekazany argument (ścieżka do projektu)
if CommandLine.arguments.count > 1 {
    // Zapisz pierwszy argument jako ścieżkę do projektu
    delegate.projectPath = CommandLine.arguments[1]
}

// Ustaw delegata aplikacji
app.delegate = delegate

// Uruchom aplikację (blokuje wykonanie do momentu zakończenia aplikacji)
app.run()
