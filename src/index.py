#!/usr/bin/env python3

# import sys
# from PyQt5.QtCore import QFile, QTextStream
# from PyQt5.QtWidgets import QApplication
# import breeze_resources

# app = QApplication(sys.argv)
# file = QFile(":/dark.qss")
# file.open(QFile.ReadOnly | QFile.Text)
# stream = QTextStream(file)
# app.setStyleSheet(stream.readAll())

from PyQt6.QtWidgets import QApplication, QWidget, QFileDialog, QLabel, QFrame, QPushButton, QVBoxLayout, QGridLayout, QSizePolicy, QHBoxLayout
from PyQt6.QtCore import Qt

from main import run
from config import read_config, write_config
from language import German

import sys
from datetime import datetime

class App(QWidget):

    def __init__(self, Language):
        super().__init__()
      
        self.T = Language
        self.title = self.T.app_name
        self.left = 10
        self.top = 10
        self.width = 800
        self.height = 500
        self.initUi()
    
    def action(self):

        if self.config.paths.schema == "" or self.config.paths.template == "":

            self.heading.setText(self.T.heading_missing_files)

            return

        self.heading.setText(self.T.heading_loading)

        current_time = datetime.now().strftime("%d:%m:%Y-%H:%M:%S")

        output_folder_name = f"{self.config.paths.start}/rechnungen-{current_time}"

        try:
            self.config = run(self.config, output_folder_name)

            write_config(self.config)
        
            self.heading.setText(self.T.heading_success)

            QFileDialog.getOpenFileName(self, self.T.dialog_output_title, output_folder_name, self.T.dialog_output_files)
        
        except Exception as err:

            self.heading.setText(self.T.error(err))
    
    def initUi(self):

        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        self.config = read_config()

        heading = QLabel(self.T.heading_default)
        heading.setStyleSheet("font: bold 20pt") 
        heading.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.heading = heading

        schema_button = QPushButton(self.T.button_schema_success if self.config.paths.schema != "" else self.T.button_schema_default)
        schema_button.setStyleSheet("font: bold 16pt; padding: 20px;")
        schema_button.clicked.connect(lambda: self.openSchemaFileDialog(schema_button))

        template_button = QPushButton(self.T.button_template_success if self.config.paths.template != "" else self.T.button_template_default)
        template_button.setStyleSheet("font: bold 16pt; padding: 20px;") 
        template_button.clicked.connect(lambda: self.openTemplateFileDialog(template_button))

        action_button = QPushButton(self.T.button_action_default)
        action_button.setStyleSheet("font: bold 16pt; padding: 20px;") 
        action_button.clicked.connect(self.action)

        layout = QGridLayout()
        layout.addWidget(heading, 0, 0, 1, 2) # y, x, colSpan, rowSpan
        layout.addWidget(schema_button, 1, 0, 1, 2)
        layout.addWidget(template_button, 2, 0, 1, 2)
        layout.addWidget(action_button, 3, 0, 1, 2)

        self.setLayout(layout)
        
        self.show()
    
    def openSchemaFileDialog(self, button):

        file_path, _ = QFileDialog.getOpenFileName(self, self.T.dialog_schema_title, self.config.paths.start, self.T.dialog_schema_files)
      
        if file_path:
            self.config.paths.schema = file_path

            print(f"setting schema path to {file_path}")

            write_config(self.config)
        
            button.setText(self.T.button_schema_success)

    def openTemplateFileDialog(self, button):

        file_path, _ = QFileDialog.getOpenFileName(self, self.T.dialog_template_title, self.config.paths.start, self.T.dialog_template_files)
      
        if file_path:
            self.config.paths.template = file_path

            print(f"setting template path to {file_path}")

            write_config(self.config)
    
            button.setText(self.T.button_template_success)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    ex = App(German)
    sys.exit(app.exec())
