## ---------- Stage 1: builder ----------
## Aqui vive el toolchain de compilacion. Nada de esto llega a la imagen final.
FROM python:3.10-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/opt/hf-cache \
    PATH="/opt/venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

## Todas las deps se instalan dentro de un venv que luego se copia entero
RUN python -m venv /opt/venv

## El pip que trae el venv es viejo y rechaza metadata de wheels recientes
## (p.ej. typing_extensions 4.16: "inconsistent Name"). Actualizarlo lo evita.
RUN pip install --no-cache-dir --upgrade pip

## CPU-only torch: sentence-transformers arrastra ~2.5GB de wheels CUDA
## que no sirven de nada sin GPU. Esto lo baja a ~200MB.
RUN pip install --no-cache-dir torch==2.3.1 \
    --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

## Bake the embedding model into the image (no download on first run)
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"


## ---------- Stage 2: runtime ----------
FROM python:3.10-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/opt/hf-cache \
    PATH="/opt/venv/bin:$PATH"

## libgomp1 es la unica dep de sistema que torch necesita en runtime.
## Sin esto, "import torch" falla con libgomp.so.1: cannot open shared object file.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

## Solo los artefactos: venv con las deps ya compiladas + cache del modelo
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/hf-cache /opt/hf-cache

## Copying ur all contents from local to app
COPY . .

## Register the project packages (deps ya estan en el venv)
RUN pip install --no-cache-dir --no-deps -e .

# Used PORTS
EXPOSE 8501

## Healthcheck via python: evita tener que instalar curl en el runtime
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8501/_stcore/health', timeout=4).status==200 else 1)"

# Builds the vector store if missing, then runs the app
CMD ["python", "docker/entrypoint.py"]
