*==============================================================
* variable_setup.do
* 变量定义模板 — 复制此文件并填入你自己的变量
*==============================================================

*--- 1. 数据路径 ---
* 训练数据路径（包含历史数据，用于训练模型）
local train_data "D:/yourpath/train_data.dta"

* 预测数据路径（包含未来年份的输入变量数据）
local predict_data "D:/yourpath/predict_data.dta"

*--- 2. 时间范围 ---
* 训练数据的时间范围（用于筛选训练样本）
local year_min = 2011
local year_max = 2024

* 是否有 year 变量（用于可视化 x 轴）
local has_year = 1

*--- 3. 输入变量列表 ---
* 在这里列出所有用于预测的自变量（空格分隔）
* 示例：
*   local input_vars "x1 x2 x3 x4"
* 可以包含原始变量或派生变量（先在下方生成派生变量，再加入列表）
local input_vars "var1 var2 var3 var4 var5"

*--- 4. 输出变量 ---
* 你要预测的目标变量
local output_var "y"

*--- 5. 神经网络参数 ---
local hidden_layers "10 10"   // 隐藏层结构，如 "5" 或 "10 10" 或 "20 10 5"
local iterations    500        // 训练迭代次数
local eta           1          // 学习率（eta），越大收敛越快但可能震荡
local model_name    "nnmodel"  // 模型保存文件名

*--- 6. 派生变量定义（可选） ---
* 如果需要从原始变量计算新变量，在这里定义
* gen derived_var1 = raw_var1 / raw_var2
* gen derived_var2 = raw_var1 + raw_var2 + raw_var3

*--- 7. 设置全局宏（不要修改以下内容） ---
global nn_input_vars  "`input_vars'"
global nn_output_var  "`output_var'"
global nn_hidden      "`hidden_layers'"
global nn_iter        `iterations'
global nn_eta         `eta'
global nn_model_name  "`model_name'"
global nn_train_data  "`train_data'"
global nn_predict_data "`predict_data'"
global nn_year_min    `year_min'
global nn_year_max    `year_max'
global nn_has_year    `has_year'
