function [trend_curve,n] = Trendcurve(data,loess_value,spline_value)

    % 提取时间和值
    time = data(:, 1);
    values = data(:, 2);

    % 1. 获取所有唯一时间点
    unique_times = unique(time);

    % 2. 对数据进行分组平滑处理（如取中位数/均值）
    smoothed_values = zeros(size(unique_times));
    for i = 1:length(unique_times)
        smoothed_values(i) = mean(values(time == unique_times(i)));
    end

    % 3. 使用 LOESS 局部加权回归平滑
    % LOESS 对于局部非线性趋势效果很好
    % dense_times 现在不再使用预设的500个点，而是使用 `data(end, 1)` 确定的长度

    % 查找该列的最大值
    minValue = min(data(:, 1));
    maxValue = max(data(:, 1));

    % 查找该列的最小值
    % 
    % minValue = min(data(:, 1));
    % n = maxValue - minValue + 1;  % 读取数据矩阵最后一行的第一个数作为n
    n=maxValue - minValue + 1;  % 读取数据矩阵最后一行的第一个数作为n
    dense_times = linspace(min(unique_times), max(unique_times), n); % 根据n生成稠密时间点

    % LOESS 平滑
    loess_smoothed = smooth(unique_times, smoothed_values, loess_value, 'loess'); % 平滑因子 0.1，可调整

    % 4. 使用样条拟合进一步平滑
    spline_curve = csaps(unique_times, loess_smoothed, spline_value); % 平滑参数 0.9，可调整
    trend_curve = fnval(spline_curve, dense_times); % 计算稠密点上的样条值


end