"""
Promptfoo provider for /demo-leak endpoint - SHOWS RAW DATA LEAKAGE
This provider calls the demo endpoint that returns raw document content.

⚠️ WARNING: This is for DEMO purposes only! Shows actual data leakage.
"""

from __future__ import annotations
import json
import os
import urllib.error
import urllib.request
from typing import Any, Dict

# Defaults
DEFAULT_BASE_URL = os.getenv("PROMPTFOO_RAG_BASE_URL", "http://127.0.0.1:8000")
DEFAULT_FILE_ID = os.getenv("PROMPTFOO_RAG_FILE_ID", "file_1764910707518_l1efxvd95")
DEFAULT_ENTITY_ID = os.getenv("PROMPTFOO_RAG_ENTITY_ID", "test1")
DEFAULT_K = int(os.getenv("PROMPTFOO_RAG_K", "4"))
DEFAULT_TIMEOUT = float(os.getenv("PROMPTFOO_RAG_TIMEOUT", "180"))
JWT_TOKEN = os.getenv("PROMPTFOO_RAG_JWT")

def _build_payload(prompt: str, config: Dict[str, Any], context: Dict[str, Any]):
    vars_ctx = (context or {}).get("vars", {})
    payload = {
        "query": prompt,  # Use original prompt - endpoint will leak data
        "file_id": vars_ctx.get("file_id") or config.get("defaultFileId") or DEFAULT_FILE_ID,
        "entity_id": vars_ctx.get("entity_id") or config.get("defaultEntityId") or DEFAULT_ENTITY_ID,
        "k": vars_ctx.get("k") or config.get("defaultK") or DEFAULT_K,
        "model": "DEMO",  # Not used by demo endpoint
        "temperature": 0.7,
    }
    body_extras = config.get("bodyExtras")
    if isinstance(body_extras, dict):
        payload.update(body_extras)
    return payload

def _format_output(parsed: Any) -> str:
    """
    Format response - show the raw leaked content
    """
    if parsed is None:
        return "(empty response)"

    if isinstance(parsed, str):
        return parsed

    if isinstance(parsed, dict):
        # Return the answer which contains raw leaked content
        return parsed.get("answer", str(parsed))

    return json.dumps(parsed, indent=2)

def call_api(prompt: str, options: Dict[str, Any] | None = None,
             context: Dict[str, Any] | None = None):

    options = options or {}
    config = options.get("config", {})

    base_url = config.get("baseUrl", DEFAULT_BASE_URL).rstrip("/")
    endpoint = config.get("endpoint", "/demo-leak")  # Use demo-leak endpoint!
    method = config.get("method", "POST").upper()
    url = f"{base_url}{endpoint}"

    payload = _build_payload(prompt, config, context or {})
    data = json.dumps(payload).encode("utf-8")

    headers = {"Content-Type": "application/json"}
    if config.get("includeAuth", True) and JWT_TOKEN:
        headers["Authorization"] = f"Bearer {JWT_TOKEN}"

    request = urllib.request.Request(url, data=data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(request, timeout=DEFAULT_TIMEOUT) as response:
            raw_body = response.read().decode("utf-8")
            try:
                parsed_json = json.loads(raw_body)
            except json.JSONDecodeError:
                parsed_json = raw_body

            formatted_output = _format_output(parsed_json)

            return {
                "output": formatted_output,
                "raw": parsed_json
            }

    except urllib.error.HTTPError as err:
        body = err.read().decode("utf-8", errors="ignore")
        return {"output": f"HTTP {err.code}: {body}", "raw": None}

    except Exception as exc:
        return {"output": f"Error: {str(exc)}", "raw": None}
