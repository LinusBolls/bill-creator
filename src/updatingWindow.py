from PyQt6.QtWidgets import QApplication, QWidget, QFileDialog, QLabel, QFrame, QPushButton, QVBoxLayout, QGridLayout, QSizePolicy, QHBoxLayout
from PyQt6.QtCore import Qt

import signal
import os
import sys
from threading import Thread

class App(QWidget):

    def listen_to_stdin(self):

        while True:

            line = sys.stdin.readline()

            cmd = line.strip()

            if len(cmd) != 0:

              self.heading.setText(cmd)

    def __init__(self):
        super().__init__()

        self.title = "Der Schuldner - Updating"
        self.left = 10
        self.top = 10
        self.width = 800
        self.height = 500

        self.initUi()

        self.thread = Thread(target = self.listen_to_stdin)
        self.thread.start()
  
    def initUi(self):

        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        heading = QLabel("Updating...")
        heading.setStyleSheet("font: bold 20pt") 
        heading.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.heading = heading

        layout = QGridLayout()
        layout.addWidget(heading, 0, 0, 1, 2) # y, x, colSpan, rowSpan

        self.setLayout(layout)
        
        self.show()

if __name__ == "__main__":

    app = QApplication(sys.argv)

    ex = App()
  
    sys.exit(app.exec())

