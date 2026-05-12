*==============================================================
* nn_predict_core.do
* 神经网络预测核心逻辑封装
* 基于 Stata brain 命令，提供通用的 define / train / predict / visualize 流程
*
* 使用方式：在主 do 文件中通过 do nn_predict_core.do 调用
* 调用前需定义以下全局宏：
*   $nn_input_vars   — 输入变量列表（空格分隔）
*   $nn_output_var   — 输出变量名
*   $nn_hidden       — 隐藏层结构（如 "10 10"）
*   $nn_iter         — 迭代次数
*   $nn_eta          — 学习率
*   $nn_model_name   — 模型保存名称
*==============================================================

*--- 参数校验 ---
if "$nn_input_vars" == "" {
    di as error "错误：未定义输入变量 $nn_input_vars，请在主文件中设置"
    exit 198
}
if "$nn_output_var" == "" {
    di as error "错误：未定义输出变量 $nn_output_var，请在主文件中设置"
    exit 198
}
if "$nn_hidden" == "" {
    local nn_hidden "10 10"
    di as text "提示：未指定隐藏层结构，使用默认值 10 10"
}
else {
    local nn_hidden "$nn_hidden"
}
if "$nn_iter" == "" {
    local nn_iter 500
    di as text "提示：未指定迭代次数，使用默认值 500"
}
else {
    local nn_iter $nn_iter
}
if "$nn_eta" == "" {
    local nn_eta 1
    di as text "提示：未指定学习率，使用默认值 1"
}
else {
    local nn_eta $nn_eta
}
if "$nn_model_name" == "" {
    local nn_model_name "nnmodel"
    di as text "提示：未指定模型名称，使用默认值 nnmodel"
}
else {
    local nn_model_name "$nn_model_name"
}

*--- Step 1: 描述性统计 ---
di _newline as text "=========================================="
di as text " 输入变量描述性统计"
di as text "=========================================="
sum $nn_input_vars $nn_output_var

*--- Step 2: 定义神经网络结构 ---
di _newline as text "=========================================="
di as text " 定义神经网络结构"
di as text " 输入变量：$nn_input_vars"
di as text " 输出变量：$nn_output_var"
di as text " 隐藏层：`nn_hidden'"
di as text "=========================================="
brain define, input($nn_input_vars) output($nn_output_var) hidden(`nn_hidden')

*--- Step 3: 训练神经网络 ---
di _newline as text "=========================================="
di as text " 开始训练（迭代 `nn_iter' 次，eta = `nn_eta'）"
di as text "=========================================="
brain train, iter(`nn_iter') eta(`nn_eta')

*--- Step 4: 保存模型 ---
brain save `nn_model_name'
di as text "模型已保存为：`nn_model_name'"

*--- Step 5: 生成训练集预测值 ---
di _newline as text "=========================================="
di as text " 生成训练集预测值"
di as text "=========================================="
local pred_var "${nn_output_var}_pred"
brain think `pred_var'

*--- Step 6: 计算拟合优度 ---
* 计算残差平方和与 R²
quietly {
    gen _residual = $nn_output_var - `pred_var'
    gen _residual_sq = _residual^2
    sum $nn_output_var
    local mean_y = r(mean)
    gen _total_sq = ($nn_output_var - `mean_y')^2
    sum _residual_sq
    local ss_res = r(sum)
    sum _total_sq
    local ss_tot = r(sum)
    local r2 = 1 - `ss_res' / `ss_tot'
    drop _residual _residual_sq _total_sq
}

di _newline as text "=========================================="
di as text " 拟合结果"
di as text " 残差平方和 (SSR) = `ss_res'"
di as text " 判定系数 (R²)    = `r2'"
di as text "=========================================="

*--- Step 7: 可视化拟合效果 ---
di _newline as text "=========================================="
di as text " 绘制拟合效果图"
di as text "=========================================="
if "`year'" != "" {
    twoway (scatter $nn_output_var year, sort) (line `pred_var' year, sort), ///
        title("神经网络拟合效果") ///
        ytitle("$nn_output_var") xtitle("年份") ///
        legend(order(1 "实际值" 2 "预测值"))
}
else {
    twoway (scatter $nn_output_var `pred_var'), ///
        title("神经网络拟合效果") ///
        ytitle("实际值") xtitle("预测值") ///
        note("R² = `r2'")
}

di _newline as text "=========================================="
di as text " 训练完成"
di as text "=========================================="

*==============================================================
* 预测函数（供外部调用）
* 用法：在加载模型后，调用 nn_predict 来生成预测值
* 需要预先设置 $nn_output_var
*==============================================================
capture program drop nn_predict
program define nn_predict
    syntax [, output_var(string)]

    if "`output_var'" == "" {
        local output_var "${nn_output_var}_pred"
    }

    di _newline as text "=========================================="
    di as text " 使用已加载模型进行预测"
    di as text " 预测变量名：`output_var'"
    di as text "=========================================="
    brain think `output_var'
    di as text "预测完成，变量 `output_var' 已生成"
end

*==============================================================
* 模型加载函数
* 用法：nn_load model_name
*==============================================================
capture program drop nn_load
program define nn_load
    args model_name
    if "`model_name'" == "" {
        di as error "错误：请指定模型名称"
        exit 198
    }
    di as text "加载模型：`model_name'"
    brain load `model_name'
    di as text "模型加载完成"
end
