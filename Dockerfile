FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/opt/hf \
    PLAYWRIGHT_BROWSERS_PATH=/opt/pw \
    CHROME_BIN=/usr/bin/chromium \
    CHROMEDRIVER_PATH=/usr/bin/chromedriver \
    DISPLAY=:99

WORKDIR /app

# System deps:
#  - xvfb                : virtual display, so "visible" browsers run on a server
#  - chromium + driver   : Selenium auto-apply (Naukri / Internshala)
RUN apt-get update && apt-get install -y --no-install-recommends \
        xvfb xauth \
        chromium chromium-driver \
        curl ca-certificates \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# CPU-only torch first (the default wheel drags in ~2 GB of CUDA libs).
RUN pip install torch --index-url https://download.pytorch.org/whl/cpu \
    && pip install -r requirements.txt

# Firefox for the Playwright scrapers (+ its system libraries).
RUN playwright install --with-deps firefox \
    && rm -rf /var/lib/apt/lists/*

# Bake the embedding model into the image (no download on first request).
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"

COPY . .

RUN mkdir -p /app/uploads/resumes /data

EXPOSE 5000

# Default: API. docker-compose overrides this for worker / beat.
CMD ["xvfb-run", "-a", "-s", "-screen 0 1920x1080x24", \
     "uvicorn", "app.main:app", \
     "--host", "0.0.0.0", "--port", "5000", "--proxy-headers", \
     "--forwarded-allow-ips", "*"]
