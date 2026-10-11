# Anime Recommender · LLMOps

Recomendador de anime basado en **RAG** (Retrieval-Augmented Generation): describe en lenguaje natural qué tipo de anime te apetece y el sistema recupera los títulos más relevantes de una base vectorial y le pide a un LLM que recomiende tres, con resumen y explicación de por qué encajan.

> 🌐 Demo: [anime.edqs.online](https://anime.edqs.online) *(próximamente)*

## Características

- **Búsqueda semántica** sobre un catálogo de 269 animes (título, sinopsis y géneros) con embeddings `all-MiniLM-L6-v2` y **ChromaDB**.
- **Generación con LLM** vía **Groq** (`openai/gpt-oss-20b`) orquestado con **LangChain**.
- **Interfaz bilingüe** (English / Español) en **Streamlit**.
- **Docker multi-stage** con torch CPU-only y el modelo de embeddings incluido en la imagen.
- **Manifiesto de Kubernetes** con probes de arranque/salud y límites de recursos.

## Arquitectura

```
                    ┌──────────────────────── build (una vez) ───────────────────────┐
data/anime_with_    │  AnimeDataLoader  →  anime_updated.csv  →  VectorStoreBuilder  │
synopsis.csv ──────▶│  (título + sinopsis + géneros)            (embeddings → Chroma)│
                    └───────────────────────────────────────────────┬────────────────┘
                                                                    ▼
Usuario ──▶ Streamlit (app/app.py) ──▶ AnimeRecommendationPipeline ──▶ retriever (chroma_db/)
                     ▲                          │                              │
                     └──── 3 recomendaciones ◀── ChatGroq + prompt ◀── contexto ┘
```

## Estructura

```
app/app.py                 Interfaz Streamlit
pipeline/build_pipeline.py Construye la base vectorial a partir del CSV
pipeline/pipeline.py       Pipeline de recomendación (retriever + LLM)
src/                       Carga de datos, vector store, prompt y recomendador
config/config.py           API key y modelo
docker/entrypoint.py       Construye el índice si falta y arranca Streamlit
llmops-k8s.yaml            Deployment + Service para Kubernetes
```

## Requisitos

- Una API key de [Groq](https://console.groq.com/keys)
- Docker (recomendado) o Python 3.10

## Configuración

```bash
cp .env.example .env
# Edita .env y rellena GROQ_API_KEY (HUGGINGFACEHUB_API_TOKEN es opcional)
```

## Ejecutar con Docker (recomendado)

```bash
docker compose up -d --build
```

Abre <http://localhost:8501>. La primera vez el contenedor construye la base vectorial (unos minutos); queda persistida en `./chroma_db` y los siguientes arranques son inmediatos.

## Ejecutar en local

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install torch==2.3.1 --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements.txt
pip install -e .

python pipeline/build_pipeline.py   # solo la primera vez
streamlit run app/app.py
```

## Despliegue en Kubernetes

```bash
docker build -t llmops-app:latest .
kubectl create secret generic llmops-secrets --from-env-file=.env
kubectl apply -f llmops-k8s.yaml
```

El `Service` es de tipo `LoadBalancer` (puerto 80 → 8501) con `sessionAffinity: ClientIP`, necesario porque Streamlit mantiene el estado de sesión sobre websocket. Si lo pones detrás de un proxy/ingress, asegúrate de reenviar las cabeceras `Upgrade` y `Connection`.

## Stack

Python 3.10 · LangChain · Groq · ChromaDB · Sentence-Transformers · Streamlit · Docker · Kubernetes
