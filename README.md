# ICS Generator iOS App

Eine moderne iOS-App zum Erstellen, Importieren und Validieren von ICS-Kalenderdateien.

![Start](https://github.com/user-attachments/assets/f23244a0-e8a4-4f1f-a9f3-21623b40e9e8)
![Settings](https://github.com/user-attachments/assets/20876f4a-3a71-499d-b7d9-1afb2eff217e)
![ICS Validator](https://github.com/user-attachments/assets/4ac67454-f6ab-49fb-b6ea-9ce069f8ce7f)

## Features

- **Termine erstellen und verwalten**
  - Intuitive Benutzeroberfläche für die Terminerstellung
  - Unterstützung für wiederkehrende Termine
  - Erinnerungen und Benachrichtigungen
  - Standortauswahl für Termine

- **ICS-Funktionalität**
  - Export von Terminen als ICS-Datei
  - Import von ICS-Dateien
  - Validierung von ICS-Dateien nach RFC 5545
  - Vorschau von ICS-Inhalten

- **Benutzerfreundlichkeit**
  - Modernes SwiftUI Interface
  - Dark Mode Unterstützung
  - Anpassbare Standardeinstellungen
  - Intuitive Navigation

## Systemanforderungen

- iOS 15.0 oder neuer
- Xcode 14.0 oder neuer
- Swift 5.0 oder neuer

## Installation

<<<<<<< HEAD
1. Klone das Repository:
```bash
git clone https://github.com/Schello805/ICS-Generator.git
```
=======
### App Store
Die App ist im [App Store](https://apps.apple.com/de/app/ics-generator/id6738963683) verfügbar.
>>>>>>> 1b95d17c98aaa0a877ce255e9bd10516ab48d3e7

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
   - Fülle die Termindetails aus
   - Speichere den Termin

2. **ICS exportieren**
   - Wähle einen oder mehrere Termine aus
   - Tippe auf "Exportieren"
   - Wähle das Ziel für die ICS-Datei

3. **ICS importieren**
   - Gehe zu Einstellungen > ICS importieren
   - Wähle eine ICS-Datei aus
   - Bestätige den Import

4. **ICS validieren**
   - Gehe zu Einstellungen > ICS Validator
   - Wähle eine ICS-Datei aus
   - Prüfe die Validierungsergebnisse

## Beitragen

Wir freuen uns über Beiträge! Bitte lies unsere Beitragsrichtlinien und erstelle einen Pull Request.

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe [LICENSE](LICENSE) für Details.

## Kontakt

Michael Schellenberger - info@schellenberger.biz

Projekt Link: [https://github.com/Schello805/ICS-Generator](https://github.com/Schello805/ICS-Generator)
