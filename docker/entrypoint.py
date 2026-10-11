"""Container entrypoint: builds the vector store on first run, then serves the app."""
import os
import sys

PERSIST_DIR = os.getenv("CHROMA_PERSIST_DIR", "chroma_db")
MARKER = os.path.join(PERSIST_DIR, "chroma.sqlite3")


def main():
    if os.path.exists(MARKER):
        print(f"[entrypoint] Vector store found at {PERSIST_DIR}, skipping build.", flush=True)
    else:
        print("[entrypoint] No vector store found, building it (this takes a few minutes)...", flush=True)
        from pipeline.build_pipeline import main as build
        build()
        print("[entrypoint] Vector store built.", flush=True)

    os.execvp("streamlit", [
        "streamlit", "run", "app/app.py",
        "--server.port=8501",
        "--server.address=0.0.0.0",
        "--server.headless=true",
    ])


if __name__ == "__main__":
    sys.exit(main())
