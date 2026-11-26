from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

# Export .env into os.environ too, so code that uses os.getenv()
# (GROQ_MODEL, GEMINI_API_KEY, FERNET_KEY fallback...) also works
# outside Docker. In Docker, compose env_file already does this.
load_dotenv()


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    # true for Neon/cloud Postgres, false for local Docker Postgres
    DATABASE_SSL: bool = False

    # JWT authentication
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Used for encrypting platform credentials
    FERNET_KEY: str

    # Celery / Redis
    CELERY_BROKER_URL: str 
    CELERY_RESULT_BACKEND: str 

    # CORS: comma-separated list of allowed frontend origins
    CORS_ORIGINS: str = (
        "http://localhost:5173,http://localhost:5174,"
        "http://127.0.0.1:5173,http://127.0.0.1:5174"
    )

    @property
    def cors_origins_list(self) -> list[str]:
        return [
            o.strip().rstrip("/")
            for o in self.CORS_ORIGINS.split(",")
            if o.strip()
        ]

    # Groq
    GROQ_API_KEY: str | None = None
    GROQ_REQUIREMENT_MODEL: str = "llama-3.3-70b-versatile"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=True,
    )


settings = Settings()