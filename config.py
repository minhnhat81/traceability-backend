
import os

class Settings:
    DATABASE_URL: str = os.getenv("DATABASE_URL","postgresql+psycopg2://trace:trace@db:5432/trace_unified")
    CORS_ORIGINS = os.getenv("CORS_ORIGINS","*").split(",")
    JWKS_URL: str = os.getenv("JWKS_URL","")        # if empty -> dev mode (no verify)
    OIDC_AUD: str = os.getenv("OIDC_AUD","")
    OIDC_ISSUER: str = os.getenv("OIDC_ISSUER","")
    FABRIC: dict = {
        "peer": os.getenv("FABRIC_PEER_ENDPOINT",""),
        "channel": os.getenv("FABRIC_CHANNEL","mychannel"),
        "chaincode": os.getenv("FABRIC_CHAINCODE","anchoring"),
        "gateway_base": os.getenv("FABRIC_GATEWAY_BASE","http://gateway-sidecar:8088") # our sidecar
    }
    POLYGON: dict = {
        "rpc": os.getenv("POLYGON_RPC",""),
        "contract_address": os.getenv("POLYGON_CONTRACT",""),
        "abi_path": os.getenv("POLYGON_ABI_PATH","")
    }

settings = Settings()
