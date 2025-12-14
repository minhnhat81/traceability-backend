from functools import lru_cache
from pydantic_settings import BaseSettings
from pydantic import AnyUrl, Field
from typing import List, Optional


class Settings(BaseSettings):
    APP_NAME: str = "traceability-api"
    ENV: str = "development"
    DEBUG: bool = False

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8022

    # Database
    DATABASE_URL: str

    # ===============================
    # 🔐 Security / Auth Configuration
    # ===============================
    JWKS_URL: Optional[AnyUrl] = None
    JWT_AUDIENCE: Optional[str] = None
    JWT_ISSUER: Optional[str] = None
    JWT_ALGORITHMS: List[str] = ["RS256"]
    JWT_CLOCK_SKEW: int = 60  # seconds

    # ✅ Bổ sung các trường cho chế độ local JWT
    JWT_SECRET: Optional[str] = None
    SECRET_KEY: Optional[str] = None  # fallback nếu JWT_SECRET không có
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 1440

    # CORS
    CORS_ALLOWED_ORIGINS: List[str] = Field(
        default_factory=lambda: ["http://localhost:5173", "http://localhost:5174"]
    )

    # Observability
    LOG_LEVEL: str = "INFO"
    SENTRY_DSN: Optional[str] = None
    OTEL_EXPORTER_OTLP_ENDPOINT: Optional[str] = None

    class Config:
        env_file = ".env"
        extra = "ignore"


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore


settings = get_settings()
