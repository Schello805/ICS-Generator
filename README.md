# ICS Generator iOS App

Eine moderne iOS-App zum Erstellen, Importieren und Validieren von ICS-Kalenderdateien.

## Features

- **Termine erstellen und verwalten**
  - Intuitive Benutzeroberfläche für die Terminerstellung
  - Unterstützung für Ganztages-Termine
  - Standortauswahl für Termine
  - Notizen und URL-Unterstützung

- **ICS-Funktionalität**
  - Zuverlässiger Export von Terminen als ICS-Datei
  - Validierung von ICS-Dateien nach RFC 5545
  - Vorschau von ICS-Inhalten
  - Einfaches Teilen über das System-Share-Sheet

- **Benutzerfreundlichkeit**
  - Modernes SwiftUI Interface
  - Dark Mode Unterstützung
  - Anpassbare Export-Einstellungen
  - Intuitive Navigation und Suche
  - Gruppierung nach Monaten

## Systemanforderungen

- iOS 15.0 oder neuer
- Xcode 14.0 oder neuer
- Swift 5.0 oder neuer

## Installation

### App Store
Die App ist im [App Store](https://apps.apple.com/de/app/ics-generator/id6738963683) verfügbar.

### Entwicklung
1. Klone das Repository:
```bash
git clone https://github.com/Schello805/ICS-Generator.git
```

2. Öffne das Projekt in Xcode:
```bash
cd ICS-Generator
open ICS-Generator.xcodeproj
```

3. Baue und starte die App in Xcode

## Projektstruktur

```
ICS-Generator/
├── App/                 # App-Einstiegspunkt
├── Assets.xcassets/     # App-Assets und Farben
├── Models/             # Datenmodelle
├── Resources/          # Ressourcen und Lokalisierungen
├── Utilities/          # Hilfsfunktionen
│   ├── Extensions/     # Swift-Erweiterungen
│   ├── Handlers/       # Error Handler
│   └── Platform/       # Plattform-spezifischer Code
├── ViewModels/         # View Models (MVVM)
└── Views/              # SwiftUI Views
    ├── Events/         # Event-bezogene Views
    ├── ICS/            # ICS-Funktionalität
    ├── Main/           # Haupt-App-Views
    ├── Settings/       # Einstellungen
    └── Shared/         # Wiederverwendbare Views
```

## Verwendung

1. **Termine erstellen**
   - Tippe auf den Plus-Button
   - Fülle die Termindetails aus (Titel, Datum, Zeit)
   - Optional: Füge Standort, Notizen oder URL hinzu
   - Speichere den Termin

2. **ICS exportieren**
   - Wähle einen oder mehrere Termine aus
   - Tippe auf den "Teilen"-Button
   - Wähle zwischen Vorschau oder direktem Teilen
   - Nutze das System-Share-Sheet zum Teilen der ICS-Datei

3. **Termine suchen**
   - Nutze die Suchleiste am oberen Bildschirmrand
   - Filtere nach Titel oder Datum
   - Termine werden nach Monaten gruppiert angezeigt

4. **Termine verwalten**
   - Lange auf einen Termin tippen für Kontextmenü
   - Bearbeiten oder Löschen von Terminen
   - Direktes Teilen einzelner Termine

## Letzte Änderungen

- Verbesserte ICS-Export-Funktionalität
- Optimierte Datei-Sharing-Funktion
- Erweiterte Fehlerbehandlung
- Verbesserte Benutzerführung

## Beitragen

Wir freuen uns über Beiträge! Bitte lies unsere Beitragsrichtlinien und erstelle einen Pull Request.

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe [LICENSE](LICENSE) für Details.

## Kontakt

Michael Schellenberger - info@schellenberger.biz

Projekt Link: [https://github.com/Schello805/ICS-Generator](https://github.com/Schello805/ICS-Generator)
