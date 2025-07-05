import json
import os

class ConfigurationManager:
  def __init__(self, config_file_path):
    self.config_file_path = config_file_path
    self.config_values = self.read_json_file()

  def read_json_file(self):
    if not os.path.exists(self.config_file_path):
      raise FileNotFoundError(f"Config file {self.config_file_path} not found.")
    try:
      with open(self.config_file_path, 'r') as file:
        config_values = json.load(file)
        self._validate_config(config_values)
        print(f"Reading configuration from {self.config_file_path}")
        return config_values
    except json.JSONDecodeError as e:
      raise ValueError(f"Error decoding JSON from {self.config_file_path}: {e}")

  def _validate_config(self, config):
    required_keys = ['PROJECT_NAME', 'MACHINE_ID_CAPS', "MACHINE_ID", "NUM_PARAMETERS", "templateDir", "outputDir"]
    for key in required_keys:
      if key not in config:
        raise ValueError(f"Missing required key '{key}' in config file")
    
    if not os.path.exists(config['templateDir']):
      raise FileNotFoundError(f"Template directory {config['templateDir']} not found.")
    
    if not os.path.exists(config['outputDir']):
      raise FileNotFoundError(f"Output directory {config['outputDir']} not found.")

  def get_config_values(self):
    return {key: value for key, value in self.config_values.items()}
