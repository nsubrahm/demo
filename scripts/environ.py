import os
from jinja2 import Environment, FileSystemLoader

class EnvironmentFilesGenerator:
    def __init__(self, configValues):
      self.templateDir = configValues["templateDir"]
      self.outputDir = configValues["outputDir"]
      self.configValues = configValues
      self.env = Environment(loader=FileSystemLoader(self.templateDir))
        
    def check_folder_exists(self, folder_path):
      if not os.path.exists(folder_path):
        raise FileNotFoundError(f"Folder does not exist: {folder_path}")

    def generate_general_env_files(self):
        general_template_dir = os.path.join(self.templateDir, "general")
        general_output_dir = os.path.join(self.outputDir, "general")
        self.check_folder_exists(general_template_dir)
        self.check_folder_exists(general_output_dir)

        print(f"Reading general templates from {general_template_dir} and writing to {general_output_dir}")
        for template_file in os.listdir(general_template_dir):
            if template_file.endswith('.tmpl'):
                template = Environment(loader=FileSystemLoader(general_template_dir)).get_template(template_file)
                output_content = template.render(**self.configValues)
                output_file_name = template_file.replace('.tmpl', '.env')
                output_file_path = os.path.join(general_output_dir, output_file_name)
                with open(output_file_path, 'w') as output_file:
                    output_file.write(output_content)
                print(f"\tGenerated .env file {output_file_path} from template file {template_file}")

    def generate_machine_env_files(self, machineId):
        machine_template_dir = os.path.join(self.templateDir, "machine")
        machine_output_dir = os.path.join(self.outputDir, machineId)
        self.check_folder_exists(machine_template_dir)
        self.check_folder_exists(machine_output_dir)

        print(f"Reading machine templates from {machine_template_dir} and writing to {machine_output_dir}")
        for template_file in os.listdir(machine_template_dir):
            if template_file.endswith('.tmpl'):
                template = Environment(loader=FileSystemLoader(machine_template_dir)).get_template(template_file)
                output_content = template.render(**self.configValues)
                output_file_name = template_file.replace('.tmpl', '.env')
                output_file_path = os.path.join(machine_output_dir, output_file_name)
                with open(output_file_path, 'w') as output_file:
                    output_file.write(output_content)
                print(f"\tGenerated .env file {output_file_path} from template file {template_file}")

