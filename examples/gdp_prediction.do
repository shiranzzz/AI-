*==============================================================
* gdp_prediction.do
* 示例：GDP 预测
*
* 展示如何将神经网络预测工具应用于不同场景
* 输入变量：固定资产投资、社会消费品零售总额、进出口总额、
*           财政支出、城镇人口占比
* 输出变量：国内生产总值 (GDP)
*==============================================================
clear all
set more off

*--- 数据路径 ---
local train_data   "D:/yourpath/gdp_train.dta"
local predict_data "D:/yourpath/gdp_predict.dta"

*--- 时间筛选 ---
local year_min = 2000
local year_max = 2024

*==============================================================
* 派生变量生成（根据你的数据调整）
*==============================================================
use "`train_data'", clear
keep if year >= `year_min' & year <= `year_max'

* 示例派生变量（根据实际数据修改）
* gen invest_ratio = gudingzichan / gdp
* gen consume_ratio = xiaofei / gdp
* gen urban_ratio = chengzhenrenkou / zongrenkou

*--- 设置神经网络参数 ---
* 修改下方变量名为你数据中的实际变量名
global nn_input_vars  "gudingzichan xiaofei jinchukou caizheng urban_ratio"
global nn_output_var  "gdp"
global nn_hidden      "10 5"
global nn_iter        1000
global nn_eta         0.5
global nn_model_name  "gdp_nnmodel"

*--- 加载核心逻辑并训练 ---
do "../nn_predict_core.do"

save "gdp_train_result.dta", replace

*==============================================================
* 预测阶段
*==============================================================
clear
use "`predict_data'", clear

* 生成同样的派生变量
* gen invest_ratio = gudingzichan / gdp
* gen consume_ratio = xiaofei / gdp
* gen urban_ratio = chengzhenrenkou / zongrenkou

* 加载模型并预测
nn_load "gdp_nnmodel"
nn_predict, output_var(gdp_pred)

save "gdp_predict_result.dta", replace
di as text "GDP 预测完成，结果保存为 gdp_predict_result.dta"
