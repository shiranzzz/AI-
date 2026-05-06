"""RAG 知识库 — Streamlit 界面"""

import tempfile
from pathlib import Path

import streamlit as st

from ingestion import ingest_file, list_indexed_files, delete_file
from query import query

st.set_page_config(page_title="RAG 知识库", layout="wide")
st.title("📚 RAG 个人知识库")

# 初始化 session 状态
if "messages" not in st.session_state:
    st.session_state.messages = []


# ------ 侧边栏：文档管理 ------
with st.sidebar:
    st.header("文档管理")

    uploaded_files = st.file_uploader(
        "上传 PDF 或 TXT 文件",
        type=["pdf", "txt"],
        accept_multiple_files=True,
    )

    if uploaded_files:
        with st.spinner("正在处理文档..."):
            for uploaded_file in uploaded_files:
                with tempfile.NamedTemporaryFile(
                    delete=False, suffix=Path(uploaded_file.name).suffix
                ) as tmp:
                    tmp.write(uploaded_file.getvalue())
                    tmp_path = tmp.name

                try:
                    chunk_count = ingest_file(tmp_path)
                    st.success(f"✅ {uploaded_file.name}（{chunk_count} 个片段）")
                except Exception as e:
                    st.error(f"❌ {uploaded_file.name}: {e}")
                finally:
                    Path(tmp_path).unlink(missing_ok=True)

    st.divider()

    # 已索引文件列表
    st.subheader("已索引文件")
    files = list_indexed_files()

    if not files:
        st.caption("暂无文件")
    else:
        for f in files:
            col1, col2 = st.columns([4, 1])
            col1.write(f"{f['name']} ({f['chunks']} 块)")
            if col2.button("删除", key=f"del_{f['name']}"):
                delete_file(f["name"])
                st.rerun()

    st.divider()
    st.caption("确保 Ollama 已启动并加载了模型")


# ------ 主区域：问答 ------
st.header("💬 问答")

# 显示历史消息
for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])
        if "sources" in msg:
            with st.expander("📎 引用来源"):
                for src in msg["sources"]:
                    st.write(f"**来自:** {src['source']}")
                    st.write(src["content"][:300] + "...")
                    st.divider()

# 输入框
if prompt := st.chat_input("输入你的问题..."):
    # 添加用户消息
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    # 检查是否有文档
    files = list_indexed_files()
    if not files:
        with st.chat_message("assistant"):
            st.warning("请先上传文档再提问")
        st.session_state.messages.append({
            "role": "assistant",
            "content": "请先在左侧上传文档，然后我才能回答你的问题。",
        })
    else:
        with st.chat_message("assistant"):
            with st.spinner("思考中..."):
                try:
                    result = query(prompt)
                    st.markdown(result["answer"])

                    if result["sources"]:
                        with st.expander("📎 引用来源"):
                            for src in result["sources"]:
                                st.write(f"**来自:** {src['source']}")
                                st.write(src["content"][:300] + "...")
                                st.divider()

                    st.session_state.messages.append({
                        "role": "assistant",
                        "content": result["answer"],
                        "sources": result["sources"],
                    })
                except Exception as e:
                    error_msg = f"查询失败: {e}"
                    st.error(error_msg)
                    st.session_state.messages.append({
                        "role": "assistant",
                        "content": error_msg,
                    })
