# language: de

Funktionalität: Startseite

  Um einen Überblick über das ausleihbare Inventar zu erhalten
  möchte ich als Ausleiher
  einen Einstieg/Übersicht über das ausleihbare Inventar

  Szenario: Startseite
    Angenommen man ist "Normin"
    Und man befindet sich auf der Seite der Hauptkategorien
    Dann sieht man genau die für den User bestimmte Haupt-Kategorien mit Bild und Namen
    Wenn man eine Hauptkategorie auswählt
    Dann lande ich in der Modellliste für diese Hauptkategorie

  @javascript
  Szenario: Haupt-Kategorien aufklappen
    Angenommen man ist "Normin"
    Und man befindet sich auf der Seite der Hauptkategorien
    Wenn ich über eine Hauptkategorie mit Kindern fahre
    Dann sehe ich nur die Kinder dieser Hauptkategorie, die dem User zur Verfügung stehende Gegenstände enthalten
    Wenn ich eines dieser Kinder anwähle
    Dann lande ich in der Modellliste für diese Kategorie

  @javascript
  Szenario: Kinder-Kategorien Dropdown nicht sichtbar
    Angenommen man ist "Normin"
    Und man befindet sich auf der Seite der Hauptkategorien
    Und es gibt eine Hauptkategorie, derer Kinderkategorien keine dem User zur Verfügung stehende Gegenstände enthalten
    Dann hat diese Hauptkategorie keine Kinderkategorie-Dropdown
