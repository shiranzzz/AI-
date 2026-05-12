# Stata 神经网络预测通用工具

基于 Stata `brain` 命令的通用神经网络预测框架。将数据准备与模型训练解耦，用户只需修改变量名即可用于任意预测场景。

## 快速开始

### 1. 复制模板

```bash
cp nn_predict.do my_project.do
```

### 2. 修改配置

打开 `my_project.do`，修改"用户配置区"：

```stata
*--- 数据路径 ---
local train_data   "D:/data/train.dta"
local predict_data "D:/data/predict.dta"

*--- 输入变量 ---
local input_vars "var1 var2 var3 var4"

*--- 输出变量 ---
local output_var "y"

*--- 神经网络参数 ---
local hidden_layers "10 10"
local iterations    500
local eta           1
```

### 3. 运行

在 Stata 中 `do my_project.do` 即可。

## 文件结构

```
├── nn_predict.do           # 通用主模板（复制后修改变量名即可）
├── nn_predict_core.do      # 核心逻辑封装（define/train/predict/visualize）
├── templates/
│   └── variable_setup.do   # 变量定义模板（详细注释版）
├── examples/
│   ├── teacher_prediction.do   # 教师数量预测示例
│   └── gdp_prediction.do       # GDP 预测示例
└── README.md
```

## 核心流程

```
数据加载 → 派生变量生成 → brain define → brain train → brain save
                                                         ↓
预测数据加载 ← brain load ← 保存模型 ← brain think（预测值）
```

## 参数说明

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `input_vars` | 输入变量（空格分隔） | 无，必填 | `"x1 x2 x3"` |
| `output_var` | 输出变量 | 无，必填 | `"y"` |
| `hidden_layers` | 隐藏层结构 | `"10 10"` | `"5"` / `"20 10 5"` |
| `iterations` | 训练迭代次数 | `500` | `1000` |
| `eta` | 学习率 | `1` | `0.5` |
| `model_name` | 模型保存名 | `"nnmodel"` | `"my_model"` |

## 核心函数

`nn_predict_core.do` 提供两个可调用的 Stata 程序：

- **`nn_load <model_name>`** — 加载已保存的神经网络模型
- **`nn_predict [, output_var(name)]`** — 使用已加载模型生成预测值

## 使用场景

本工具适用于任何可以用结构化数据进行回归预测的场景：

- 教育资源需求预测（教师数量、学校数量）
- 经济指标预测（GDP、产值）
- 人口预测（出生率、城镇化率）
- 能源消费预测
- 医疗资源需求预测

只需替换输入/输出变量和数据路径即可。

## 依赖

- Stata 15+（需要 `brain` 命令支持）
- 安装 `brain` 包：`ssc install brain`
