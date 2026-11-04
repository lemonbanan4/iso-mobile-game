import os
from pydantic import BaseModel

class Settings(BaseModel):
    PROJECT_NAME: str = "Iso Syndicate Backend"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/v1"
    
    # Cloud Run assigns PORT dynamically (default 8080)
    PORT: int = int(os.getenv("PORT", "8080"))
    HOST: str = os.getenv("HOST", "0.0.0.0")
    DEBUG: bool = os.getenv("DEBUG", "False").lower() in ("true", "1", "yes")

settings = Settings()
