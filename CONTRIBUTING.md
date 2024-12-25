# Beitragen zum ICS Generator

Vielen Dank für Ihr Interesse am ICS Generator! Wir freuen uns über jeden Beitrag zur Verbesserung der App.

## Wie Sie beitragen können

### 1. Issues
- Melden Sie Bugs oder schlagen Sie neue Features vor
- Nutzen Sie die vorhandenen Issue-Templates
- Beschreiben Sie das Problem oder Feature möglichst genau
- Bei Bugs: Fügen Sie Schritte zur Reproduktion hinzu
- Kennzeichnen Sie Issues mit passenden Labels

### 2. Pull Requests
1. Forken Sie das Repository
2. Erstellen Sie einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committen Sie Ihre Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Pushen Sie den Branch (`git push origin feature/AmazingFeature`)
5. Öffnen Sie einen Pull Request
6. Warten Sie auf Code Review

### 3. Code-Richtlinien

#### Swift Style Guide
- Folgen Sie den [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Verwenden Sie aussagekräftige Namen für Variablen und Funktionen
- Dokumentieren Sie komplexe Funktionen mit Kommentaren
- Nutzen Sie Swift's Type System effektiv
- Verwenden Sie moderne Swift Features

#### SwiftUI Best Practices
- Halten Sie Views klein und fokussiert
- Nutzen Sie das MVVM-Pattern
- Vermeiden Sie große verschachtelte Views
- Verwenden Sie Custom ViewModifier für wiederverwendbare Styles
- Implementieren Sie Dark Mode Unterstützung
- Nutzen Sie SwiftUI Previews für schnelles Feedback

#### Accessibility
- Implementieren Sie VoiceOver Unterstützung
- Fügen Sie sinnvolle Accessibility Labels hinzu
- Testen Sie Dynamic Type Unterstützung
- Berücksichtigen Sie Kontraste für bessere Lesbarkeit

### 4. Commit Messages
- Verwenden Sie klare, beschreibende Commit-Messages
- Beginnen Sie mit einem Verb im Imperativ
- Halten Sie die erste Zeile unter 50 Zeichen
- Fügen Sie bei Bedarf eine detaillierte Beschreibung hinzu
- Referenzieren Sie relevante Issues

Beispiel:
```
Add event sharing functionality (#123)

- Implement share sheet for events
- Add ICS file generation
- Update UI with share button
- Add progress indicator for large files
```

### 5. Testing
- Fügen Sie Unit Tests für neue Funktionen hinzu
- Schreiben Sie UI Tests für kritische User Flows
- Stellen Sie sicher, dass alle Tests durchlaufen
- Testen Sie auf verschiedenen iOS-Versionen (iOS 15.0+)
- Testen Sie Dark Mode Funktionalität
- Validieren Sie ICS-Datei Generierung

### 6. Performance
- Optimieren Sie Ressourcenverbrauch
- Vermeiden Sie unnötige Berechnungen
- Implementieren Sie Lazy Loading wo sinnvoll
- Profilen Sie die App regelmäßig
- Berücksichtigen Sie Speicherverbrauch

## Code of Conduct

### Unsere Verpflichtung
Wir verpflichten uns, eine freundliche und respektvolle Umgebung zu schaffen.

### Unsere Standards
Positives Verhalten:
- Respektvolle Kommunikation
- Konstruktives Feedback
- Fokus auf Zusammenarbeit
- Hilfsbereitschaft gegenüber Neueinsteigern
- Offenheit für neue Ideen

Unerwünschtes Verhalten:
- Beleidigungen oder persönliche Angriffe
- Trolling oder destruktive Kommentare
- Jede Form von Diskriminierung
- Spam oder Off-Topic Beiträge

## Development Workflow

1. **Feature Planning**
   - Diskutieren Sie neue Features in Issues
   - Erstellen Sie einen Design-Vorschlag
   - Holen Sie Feedback ein

2. **Implementation**
   - Folgen Sie den Code-Richtlinien
   - Dokumentieren Sie Ihren Code
   - Schreiben Sie Tests

3. **Review Process**
   - Code Review durch Maintainer
   - Automatisierte Tests müssen bestehen
   - UI/UX Review bei visuellen Änderungen

4. **Release**
   - Changelog Update
   - Version Bump
   - App Store Release

## Fragen?

Bei Fragen können Sie:
- Ein Issue erstellen
- Die Wiki-Dokumentation konsultieren
- Sich an die Projekt-Maintainer wenden
- Den Discussions-Bereich nutzen

Wir freuen uns auf Ihre Beiträge!
