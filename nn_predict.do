*==============================================================
* nn_predict.do
* 神经网络预测 — 通用主模板
*
* 使用方式：
*   1. 复制本文件为你的项目主文件
*   2. 修改下方"用户配置区"的变量和路径
*   3. 在 Stata 中运行
*
* 依赖文件：nn_predict_core.do（核心逻辑）
*==============================================================
clear all
set more off

*==============================================================
*                    用户配置区（需修改）
*==============================================================

*--- 数据路径 ---
local train_data   "D:/yourpath/train_data.dta"      // 训练数据
local predict_data "D:/yourpath/predict_data.dta"    // 待预测数据

*--- 时间筛选 ---
local year_min = 2011
local year_max = 2024

*--- 输入变量（空格分隔）---
local input_vars "x1 x2 x3 x4 x5"

*--- 输出变量 ---
local output_var "y"

*--- 神经网络参数 ---
local hidden_layers "10 10"    // 隐藏层结构
local iterations    500        // 迭代次数
local eta           1          // 学习率
local model_name    "nnmodel"  // 模型文件名

*--- 派生变量（可选，在此处定义）---
* gen new_var = var1 / var2

*==============================================================
*                    执行区（无需修改）
*==============================================================

*--- 设置全局宏 ---
global nn_input_vars  "`input_vars'"
global nn_output_var  "`output_var'"
global nn_hidden      "`hidden_layers'"
global nn_iter        `iterations'
global nn_eta         `eta'
global nn_model_name  "`model_name'"

*--- 加载训练数据 ---
use "`train_data'", clear

*--- 时间筛选 ---
keep if year >= `year_min' & year <= `year_max'

*--- 加载并执行核心逻辑 ---
do "nn_predict_core.do"

*--- 保存训练结果 ---
save "train_result.dta", replace
di as text "训练结果已保存为 train_result.dta"

*==============================================================
*                    预测阶段
*==============================================================
clear
use "`predict_data'", clear

*--- 加载模型 ---
nn_load "`model_name'"

*--- 生成预测值 ---
local pred_var "${nn_output_var}_pred"
nn_predict, output_var(`pred_var')

*--- 保存预测结果 ---
save "predict_result.dta", replace
di as text "预测结果已保存为 predict_result.dta"

di _newline as text "=========================================="
di as text " 全部完成！"
di as text " 训练结果：train_result.dta"
di as text " 预测结果：predict_result.dta"
di as text "=========================================="
