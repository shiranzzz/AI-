"""文档处理模块：加载 → 分割 → 向量化 → 存储"""

import os
from pathlib import Path

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, TextLoader
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OllamaEmbeddings


CHROMA_DIR = Path(__file__).parent / "chroma_db"
CHUNK_SIZE = 500
CHUNK_OVERLAP = 100


def get_embeddings():
    return OllamaEmbeddings(
        model="bge-m3",
        base_url=os.environ.get("OLLAMA_HOST", "http://localhost:11434"),
    )


def get_vector_store():
    return Chroma(
        persist_directory=str(CHROMA_DIR),
        embedding_function=get_embeddings(),
    )


def load_document(file_path: str) -> list:
    """加载 PDF 或 TXT 文件，返回 LangChain Document 列表"""
    ext = os.path.splitext(file_path)[1].lower()
    if ext == ".pdf":
        loader = PyPDFLoader(file_path)
    elif ext == ".txt":
        # Windows 下 txt 文件可能是 GBK 编码，尝试多种编码
        loader = None
        for enc in ("utf-8", "gbk", "gb2312", "gb18030"):
            try:
                loader = TextLoader(file_path, encoding=enc)
                loader.load()
                break
            except Exception:
                continue
        if loader is None:
            raise ValueError(f"无法解码文件，尝试了 utf-8/gbk/gb2312/gb18030")
    else:
        raise ValueError(f"不支持的文件类型: {ext}，仅支持 .pdf 和 .txt")

    return loader.load()


def split_documents(docs: list) -> list:
    """将文档分割成固定大小的块"""
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=CHUNK_SIZE,
        chunk_overlap=CHUNK_OVERLAP,
        separators=["\n\n", "\n", "。", ".", " ", ""],
    )
    return splitter.split_documents(docs)


def ingest_file(file_path: str) -> int:
    """处理单个文件并存入向量库，返回 chunk 数量"""
    docs = load_document(file_path)
    chunks = split_documents(docs)

    # 给每个 chunk 带上来源文件名
    filename = os.path.basename(file_path)
    for chunk in chunks:
        chunk.metadata["source_file"] = filename

    vector_store = get_vector_store()
    vector_store.add_documents(chunks)

    return len(chunks)


def list_indexed_files() -> list[dict]:
    """列出已索引的文件及其 chunk 数量"""
    vector_store = get_vector_store()
    collection = vector_store.get(include=["metadatas"])

    file_map = {}
    for meta in collection["metadatas"]:
        if meta and "source_file" in meta:
            name = meta["source_file"]
            if name not in file_map:
                file_map[name] = 0
            file_map[name] += 1

    return [{"name": k, "chunks": v} for k, v in sorted(file_map.items())]


def delete_file(filename: str):
    """删除指定文件的所有向量记录"""
    vector_store = get_vector_store()
    collection = vector_store.get(include=["metadatas"])

    ids_to_delete = []
    for i, meta in enumerate(collection["metadatas"]):
        if meta and meta.get("source_file") == filename:
            ids_to_delete.append(collection["ids"][i])

    if ids_to_delete:
        vector_store.delete(ids_to_delete)
