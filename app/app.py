import streamlit as st
from pipeline.pipeline import AnimeRecommendationPipeline
from dotenv import load_dotenv

st.set_page_config(page_title="Anime Recommender",layout="wide")

load_dotenv()

LANGUAGES = {"English":"en", "Español":"es"}

UI = {
    "en": {
        "title": "Anime Recommender System",
        "input": "Enter your anime preferences eg. : light hearted anime with school settings",
        "spinner": "Fetching recommendations for you.....",
        "header": "### Recommendations",
    },
    "es": {
        "title": "Sistema de Recomendación de Anime",
        "input": "Escribe tus preferencias eg. : anime ligero con ambientación escolar",
        "spinner": "Buscando recomendaciones para ti.....",
        "header": "### Recomendaciones",
    },
}

@st.cache_resource
def init_pipeline():
    return AnimeRecommendationPipeline()

pipeline = init_pipeline()

language = LANGUAGES[st.sidebar.selectbox("Language / Idioma", list(LANGUAGES.keys()))]
t = UI[language]

st.title(t["title"])

query = st.text_input(t["input"])
if query:
    with st.spinner(t["spinner"]):
        response = pipeline.recommend(query,language)
        st.markdown(t["header"])
        st.write(response)
