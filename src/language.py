class German:
    app_name = "Der Schuldner"

    heading_default = "Die Sache in ihrer Güte"
    heading_loading = "Rechnungen Erstellen..."
    heading_success = "Erfolg"
    heading_missing_files = "Bitte Schema und Template Datei Hochladen"

    button_schema_default = "Schema Datei Hochladen"
    button_schema_success = "Schema Datei Hochladen ✅"
    button_template_default = "Template Datei Hochladen"
    button_template_success = "Template Datei Hochladen ✅"
    button_action_default = "Rechnungen Erstellen"

    dialog_schema_title = "Template Datei Hochladen"
    dialog_schema_files = "Excel Dateien (*.xlsx)"
    dialog_template_title = "Schema Datei Hochladen"
    dialog_template_files = "Word Dateien (*.docx)"
    dialog_output_title = "Rechnungen Ordner"
    dialog_output_files = "Keine Dateiauswahl Notwendig (*)"

    error = lambda err: f"Error: {err}"