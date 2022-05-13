import os
import json

CONFIG_PATH = os.getenv("DATA_PATH") + "/config.json"
STARTUP_PATH = os.getenv("STARTUP_PATH")

class ConfigPaths():

    def __init__(self, paths_dict):

        self.start = paths_dict["start"]
        self.schema = paths_dict["schema"]
        self.template = paths_dict["template"]

    def toJson(self):
          return json.dumps(self, default=lambda o: o.__dict__, 
              sort_keys=True, indent=4)

class Config():

    def __init__(self, currentBillIdx, paths):

        self.currentBillIdx = currentBillIdx
        self.paths = ConfigPaths(paths)

    def toJson(self):
          return json.dumps(self, default=lambda o: o.__dict__, 
              sort_keys=True, indent=4)

default_paths = {
    "start": STARTUP_PATH,
    "schema": "",
    "template": "",
}
default_config = Config(1, default_paths)

def read_config():

  if not os.path.exists(CONFIG_PATH):

    write_config(default_config)

    return read_config()

  with open(CONFIG_PATH, "r") as file:
  
    return Config(**json.loads(file.read()))

def write_config(config):

  with open(CONFIG_PATH, "w") as file:

    file.write(config.toJson())
