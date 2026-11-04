import json
import os
import sys
import yaml

# Add backend directory to sys.path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
CONTRACTS_DIR = os.path.join(BASE_DIR, "contracts")
sys.path.insert(0, BACKEND_DIR)

from app.main import app

def sync_contracts():
    os.makedirs(CONTRACTS_DIR, exist_ok=True)
    schema = app.openapi()

    json_path = os.path.join(CONTRACTS_DIR, "openapi.json")
    yaml_path = os.path.join(CONTRACTS_DIR, "openapi.yaml")

    # Write formatted JSON
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(schema, f, indent=2)

    # Write formatted YAML
    with open(yaml_path, "w", encoding="utf-8") as f:
        yaml.dump(schema, f, sort_keys=False, default_flow_style=False, allow_unicode=True)

    print(f"Authoritative OpenAPI contract synchronized to:")
    print(f" - {json_path}")
    print(f" - {yaml_path}")

if __name__ == "__main__":
    sync_contracts()
