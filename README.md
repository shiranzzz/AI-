# RAG 个人知识库

基于本地大模型的个人知识库问答系统。上传文档，AI 根据文档内容回答你的问题，数据完全本地存储，无需 API Key。

## 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| LLM | Ollama + llama3.2:1b | 本地运行，免费 |
| 嵌入模型 | Ollama + bge-m3 | 中文语义理解 |
| 向量库 | ChromaDB | 零配置，持久化存储 |
| RAG 框架 | LangChain | 文档加载→分块→检索→生成 |
| UI | Streamlit | 交互式 Web 界面 |

## 快速开始

### 1. 安装 Ollama

从 [ollama.com](https://ollama.com) 下载安装，然后拉取模型：

```bash
ollama pull llama3.2:1b
ollama pull bge-m3
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 启动

```bash
streamlit run app.py
```

打开浏览器进入 http://localhost:8501，上传文档开始提问。

## Docker 部署

```bash
# 构建镜像
docker build -t rag-knowledge-base .

# 运行（需要 Ollama 在宿主机运行）
docker run -p 8501:8501 -v ./chroma_db:/app/chroma_db rag-knowledge-base
```

或使用 docker-compose：

```bash
docker-compose up -d
```

## 项目结构

```
rag-knowledge-base/
├── app.py              # Streamlit Web 界面
├── ingestion.py        # 文档处理：加载 → 分割 → 向量化 → 存储
├── query.py            # RAG 检索 + LLM 生成回答
├── test_rag.py         # 集成测试
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── chroma_db/          # 向量数据库（自动创建，已 gitignore）
```

## 工作原理

```
用户提问 → 嵌入模型将问题向量化 → ChromaDB 检索相似文档片段
→ 将片段 + 问题发送给 LLM → LLM 基于文档内容生成回答
```

## 简历写法

```
个人知识库 RAG 问答系统 | Python, LangChain, Ollama, ChromaDB, Streamlit
- 基于 RAG 架构搭建本地知识库问答系统，支持 PDF/TXT 文档上传与语义检索
- 使用 LangChain 实现文档加载→文本分块→向量化存储→相似度检索完整流程
- 集成 Ollama 本地大模型，无需 API Key，数据本地存储确保隐私安全
- 使用 Streamlit 构建交互式 Web 界面，支持多轮对话与引用溯源
```
