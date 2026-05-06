"""查询模块：检索 + 生成"""

import os
from typing import Optional

from langchain_community.llms import Ollama
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.vectorstores import Chroma
from langchain_classic.chains import RetrievalQA
from langchain_core.prompts import PromptTemplate
from pathlib import Path

CHROMA_DIR = Path(__file__).parent / "chroma_db"
OLLAMA_BASE = os.environ.get("OLLAMA_HOST", "http://localhost:11434")

# 中文提示词模板 —— 简洁版，适合小模型
ZH_PROMPT = PromptTemplate(
    input_variables=["context", "question"],
    template=(
        "根据下面的资料回答问题。用中文回答，分条列出步骤。\n\n"
        "资料：\n{context}\n\n"
        "问题：{question}\n\n"
        "回答："
    ),
)


def _get_qa_chain(llm_model: str = "llama3.2:1b", k: int = 4):
    """构建 RAG 问答链"""
    embeddings = OllamaEmbeddings(model="bge-m3", base_url=OLLAMA_BASE)
    vector_store = Chroma(
        persist_directory=str(CHROMA_DIR),
        embedding_function=embeddings,
    )
    retriever = vector_store.as_retriever(search_kwargs={"k": k})

    llm = Ollama(model=llm_model, temperature=0.3, base_url=OLLAMA_BASE)

    qa = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=retriever,
        return_source_documents=True,
        chain_type_kwargs={"prompt": ZH_PROMPT},
    )
    return qa


def query(
    question: str,
    llm_model: str = "llama3.2:1b",
    k: int = 4,
) -> dict:
    """
    查询 RAG 知识库。

    返回:
        {"answer": str, "sources": [{"content": str, "source": str, "score": float}]}
    """
    qa = _get_qa_chain(llm_model=llm_model, k=k)
    result = qa.invoke({"query": question})

    sources = []
    seen = set()
    for doc in result.get("source_documents", []):
        content = doc.page_content.strip()
        if content not in seen:
            seen.add(content)
            sources.append({
                "content": content,
                "source": doc.metadata.get("source_file", "未知"),
            })

    return {
        "answer": result["result"],
        "sources": sources,
    }
