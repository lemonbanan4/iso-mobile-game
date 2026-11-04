#!/usr/bin/env python3
"""
CI Contract Verification & Drift Detection Script
Ensures that backend FastAPI implementation strictly matches the authoritative OpenAPI specification in /contracts.
"""
import json
import os
import sys

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKEND_DIR = os.path.join(BASE_DIR, "backend")
CONTRACT_PATH = os.path.join(BASE_DIR, "contracts", "openapi.json")

sys.path.insert(0, BACKEND_DIR)
from app.main import app

def verify_contracts() -> int:
    if not os.path.exists(CONTRACT_PATH):
        print(f"Error: Authoritative contract not found at {CONTRACT_PATH}")
        return 1

    with open(CONTRACT_PATH, "r", encoding="utf-8") as f:
        authoritative_spec = json.load(f)

    current_spec = app.openapi()

    diffs = []

    # 1. Compare Paths
    auth_paths = set(authoritative_spec.get("paths", {}).keys())
    curr_paths = set(current_spec.get("paths", {}).keys())

    missing_paths = auth_paths - curr_paths
    if missing_paths:
        diffs.append(f"BREAKING: Missing endpoints in backend: {missing_paths}")

    new_paths = curr_paths - auth_paths
    if new_paths:
        diffs.append(f"DRIFT: New undocumented endpoints added to backend: {new_paths}")

    # 2. Compare Path Operations & Methods
    for path in auth_paths.intersection(curr_paths):
        auth_methods = set(authoritative_spec["paths"][path].keys())
        curr_methods = set(current_spec["paths"][path].keys())
        if auth_methods != curr_methods:
            diffs.append(f"BREAKING: Method mismatch on {path}: spec={auth_methods}, code={curr_methods}")

    # 3. Compare Schemas
    auth_schemas = set(authoritative_spec.get("components", {}).get("schemas", {}).keys())
    curr_schemas = set(current_spec.get("components", {}).get("schemas", {}).keys())

    missing_schemas = auth_schemas - curr_schemas
    if missing_schemas:
        diffs.append(f"BREAKING: Missing Pydantic schemas in backend: {missing_schemas}")

    if diffs:
        print("❌ OpenAPI Contract Validation FAILED!")
        for diff in diffs:
            print(f"  - {diff}")
        print("\nPlease run 'python contracts/sync_contracts.py' if this change was intended and approved.")
        return 1

    print("✅ OpenAPI Contract Validation PASSED: Backend matches authoritative specification.")
    return 0

if __name__ == "__main__":
    sys.exit(verify_contracts())
