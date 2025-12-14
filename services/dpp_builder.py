# app/services/dpp_builder.py

import json
from datetime import datetime, timezone

def build_dpp_json(batch_code: str, events: list, meta=None):
    """
    Tạo DPP JSON gồm: EPCIS events, batch info, timestamp, metadata
    """
    return {
        "version": "1.0",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "batch_code": batch_code,
        "meta": meta or {},
        "epcis_events": events,
    }
