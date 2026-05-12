*==============================================================
* teacher_prediction.do
* 示例：基础教育教师数量预测
*
* 输入变量：
*   - 基础教育生师比、人均GDP、第三产业占比、城镇化率
*   - 教育业法人单位数、总和生育率、恩格尔系数、基础教育在校生数量
* 输出变量：基础教育教师数量
*==============================================================
clear all
set more off

*--- 数据路径 ---
local train_data   "D:/Desktop/教师需求规模预测/01-训练数据.dta"
local predict_data "D:/Desktop/教师需求规模预测/02-待预测数据.dta"

*--- 时间筛选 ---
local year_min = 2011
local year_max = 2024

*==============================================================
* 派生变量生成
*==============================================================
use "`train_data'", clear
keep if year >= `year_min' & year <= `year_max'

* 01-基础教育生师比
gen shengshibi = (youzaixiao + xiaozaixiao + chuzaixiao + gaozaixiao) ///
               / (youjiaoshi + xiaojiaoshi + chujiaoshi + gaojiaoshi)

* 02-人均GDP
gen renjungdp = rjgdp

* 03-第三产业占比
gen disanzhanbi = disanchanzhi / zongchanzhi

* 04-城镇化率
gen chengzhenhualv = chengzhenrenkou / zongrenkou

* 05-教育业法人单位数
gen farendanwei = jiaoyufaren

* 06-总和生育率（用出生率代理）
gen shengyulv = chushenglv

* 07-恩格尔系数
gen engeerxishu = engeer

* 08-基础教育在校生数量
gen zaixiaoshengshu = youzaixiao + xiaozaixiao + chuzaixiao + gaozaixiao

* 输出变量：基础教育教师数量
gen jichujiaoshishu = youjiaoshi + xiaojiaoshi + chujiaoshi + gaojiaoshi

*--- 设置神经网络参数 ---
global nn_input_vars  "shengshibi renjungdp disanzhanbi chengzhenhualv farendanwei shengyulv engeerxishu zaixiaoshengshu"
global nn_output_var  "jichujiaoshishu"
global nn_hidden      "10 10"
global nn_iter        500
global nn_eta         1
global nn_model_name  "teacher_nnmodel"

*--- 加载核心逻辑并训练 ---
do "../nn_predict_core.do"

save "teacher_train_result.dta", replace

*==============================================================
* 预测阶段
*==============================================================
clear
use "`predict_data'", clear

* 生成同样的派生变量
gen shengshibi = (youzaixiao + xiaozaixiao + chuzaixiao + gaozaixiao) ///
               / (youjiaoshi + xiaojiaoshi + chujiaoshi + gaojiaoshi)
gen renjungdp = rjgdp
gen disanzhanbi = disanchanzhi / zongchanzhi
gen chengzhenhualv = chengzhenrenkou / zongrenkou
gen farendanwei = jiaoyufaren
gen shengyulv = chushenglv
gen engeerxishu = engeer
gen zaixiaoshengshu = youzaixiao + xiaozaixiao + chuzaixiao + gaozaixiao

* 加载模型并预测
nn_load "teacher_nnmodel"
nn_predict, output_var(jichujiaoshishu_pred)

save "teacher_predict_result.dta", replace
di as text "教师数量预测完成，结果保存为 teacher_predict_result.dta"
