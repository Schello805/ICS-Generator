# ICS Generator iOS App

Eine moderne iOS-App zur einfachen Erstellung und Verwaltung von ICS-Kalenderdateien.

![Start](https://github.com/user-attachments/assets/f23244a0-e8a4-4f1f-a9f3-21623b40e9e8)
![Settings](https://github.com/user-attachments/assets/20876f4a-3a71-499d-b7d9-1afb2eff217e)
![ICS Validator](https://github.com/user-attachments/assets/4ac67454-f6ab-49fb-b6ea-9ce069f8ce7f)

## Features

- Umfassendes Termin-Management
  - Erstellen, Bearbeiten, Löschen und Teilen von Terminen
  - Intuitive Benutzeroberfläche im nativen iOS-Design
  - Kontextmenü und Swipe-Aktionen für schnellen Zugriff
  - Gruppierung von Terminen nach Zeiträumen (Heute, Morgen, Diese Woche, etc.)

- Erweiterte Termin-Optionen
  - Wiederholende Termine (täglich, wöchentlich, monatlich, jährlich)
  - Benutzerdefinierte Wiederholungsregeln
  - Dateianhänge (PDF-Dokumente und Bilder)
  - Standort- und URL-Unterstützung
  - Erinnerungen und Reisezeit

- Export und Teilen
  - Export von Terminen als ICS-Datei
  - Teilen via iOS Share Sheet
  - Unterstützung für Dateianhänge beim Export

- Benutzerfreundlichkeit
  - Unterstützung für Dark Mode
  - Native iOS Gesten
  - Aussagekräftige Fehlerbehandlung
  - Benutzerfreundliche Dialoge und Feedback

## Technische Details

- Entwicklung
  - Swift & SwiftUI
  - iOS 15.0+
  - MVVM Architektur
  - Lokale Datenpersistierung

- Frameworks und APIs
  - PhotosUI für Bildauswahl
  - UniformTypeIdentifiers für Dateihandling
  - EventKit für Kalenderintegration
  - SwiftUI Navigation API

- Features
  - Vollständige iCalendar (RFC 5545) Unterstützung
  - Komplexe Wiederholungsregeln (RRULE)
  - Dateianhänge in verschiedenen Formaten
  - Robuste Fehlerbehandlung

## Installation

### App Store
Die App ist im [App Store](https://apps.apple.com/de/app/ics-generator/id6738963683) verfügbar.

### Entwicklung
1. Klonen Sie das Repository
2. Öffnen Sie `ICS-Generator.xcodeproj` in Xcode
3. Wählen Sie Ihr Zielgerät oder einen Simulator
4. Drücken Sie ⌘R zum Ausführen der App

## Entwicklung

Die App verwendet die MVVM (Model-View-ViewModel) Architektur für eine klare Trennung von Logik und UI. 
Alle UI-Komponenten sind in SwiftUI implementiert und folgen den Apple Human Interface Guidelines.

### Projektstruktur
- `Models/`: Datenmodelle für Events und zugehörige Typen
- `Views/`: SwiftUI Views und UI-Komponenten
  - `EventEditorView`: Hauptview für die Terminerstellung/-bearbeitung
  - `CustomRecurrenceView`: View für benutzerdefinierte Wiederholungen
  - Verschiedene Hilfsviews für spezifische Funktionen
- `ViewModels/`: View Models für die Geschäftslogik
- `Utilities/`: Hilfsfunktionen und Erweiterungen

## Support

Bei Fragen oder Problemen erstellen Sie bitte ein [Issue](https://github.com/Schello805/ICS-Generator/issues) in diesem Repository.

## Mitwirken

Wir freuen uns über jeden Beitrag! Bitte lesen Sie unsere [Contribution Guidelines](CONTRIBUTING.md) für Details.

## Datenschutz

Die Datenschutzerklärung finden Sie [hier](PRIVACY.md).

## Lizenz

MIT License

Copyright (c) 2024 Michael Schellenberger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
