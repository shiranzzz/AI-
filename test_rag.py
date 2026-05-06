"""快速验证 RAG 全链路"""

import tempfile
from pathlib import Path

# 确保 Python 能找到 ollama（Windows 路径问题）
import os
localappdata = os.environ.get("LOCALAPPDATA", "")
ollama_path = os.path.join(localappdata, "Programs", "Ollama")
if ollama_path not in os.environ.get("PATH", ""):
    os.environ["PATH"] += os.pathsep + ollama_path

from ingestion import ingest_file, list_indexed_files
from query import query


# 创建测试文档
test_content = """人工智能（AI）是计算机科学的一个重要分支，
旨在创建能够模拟人类智能的系统。机器学习是 AI 的核心子领域，
通过数据训练模型来做出预测或决策。深度学习是机器学习的子集，
使用多层神经网络处理复杂模式。

RAG（检索增强生成）是一种结合信息检索和文本生成的 AI 架构。
它的工作流程是：接收用户问题 → 从知识库检索相关文档 →
将检索结果作为上下文提供给大语言模型 → 生成基于事实的回答。
RAG 的优势在于可以减少大模型的幻觉问题，提高回答的准确性。

Python 是 AI 开发中最流行的编程语言之一，拥有丰富的库生态：
NumPy 用于数值计算，Pandas 用于数据处理，Scikit-learn 用于机器学习，
PyTorch 和 TensorFlow 用于深度学习。"""

with tempfile.NamedTemporaryFile(
    mode="w", suffix=".txt", delete=False, encoding="utf-8"
) as f:
    f.write(test_content)
    tmp_path = f.name

print(f"[FILE] 测试文件: {tmp_path}")

# Step 1: 索引文档
print("[STEP] 正在索引文档...")
chunk_count = ingest_file(tmp_path)
print(f"[OK] 索引完成，共 {chunk_count} 个片段")

# Step 2: 列出已索引文件
files = list_indexed_files()
print(f"[INFO] 已索引文件: {files}")

# Step 3: 提问测试
questions = [
    "什么是 RAG？它有什么优势？",
    "Python 在 AI 开发中常用的库有哪些？",
]

for q in questions:
    print(f"\n[Q] 问题: {q}")
    try:
        result = query(q, llm_model="llama3.2:1b", k=3)
        print(f"[A] 回答: {result['answer'][:200]}...")
        print(f"[SOURCES] 引用来源: {len(result['sources'])} 个")
        for s in result['sources']:
            print(f"   - {s['source']}: {s['content'][:50]}...")
    except Exception as e:
        print(f"[ERROR] 错误: {e}")

# 清理
Path(tmp_path).unlink(missing_ok=True)
print("\n[DONE] 测试完成")
