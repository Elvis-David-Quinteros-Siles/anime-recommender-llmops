from langchain.chains import RetrievalQA
from langchain_groq import ChatGroq
from src.prompt_template import get_anime_prompt

class AnimeRecommender:
    def __init__(self,retriever,api_key:str,model_name:str):
        self.llm = ChatGroq(api_key=api_key,model=model_name,temperature=0)
        self.retriever = retriever
        self._chains = {}

    def _get_chain(self,language:str):
        # El retriever y el LLM se comparten; solo la cadena cambia por idioma
        if language not in self._chains:
            self._chains[language] = RetrievalQA.from_chain_type(
                llm = self.llm,
                chain_type = "stuff",
                retriever = self.retriever,
                return_source_documents = True,
                chain_type_kwargs = {"prompt":get_anime_prompt(language)}
            )
        return self._chains[language]

    def get_recommendation(self,query:str,language:str="en"):
        result = self._get_chain(language).invoke({"query":query})
        return result['result']
