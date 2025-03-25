function plotDopplerWithKalman(dopplerMatrix1,smoothedDoppler1,dopplerMatrix2,smoothedDoppler2,fig_data_folder,fig)
    % 计算时间轴
    n1 = length(dopplerMatrix1);
    n2 = length(dopplerMatrix2);
    time1 = (0:n1-1) * 0.05;
    time2 = (0:n2-1) * 0.05;

    % 创建散点图和卡尔曼平滑曲线
    fig_doppler_kf = figure;
    set(gcf, 'Position', [100, 100,400,300]);
    hold on;
    scatter(time1, dopplerMatrix1, 'b', 'filled'); % 蓝色原始数据
    plot(time1, smoothedDoppler1, 'b', 'LineWidth', 2); % 蓝色卡尔曼平滑曲线
    scatter(time2, dopplerMatrix2, 'r', 'filled'); % 红色原始数据
    plot(time2, smoothedDoppler2, 'r', 'LineWidth', 2); % 红色卡尔曼平滑曲线
    hold off;

    % 设置标签和标题
    xlabel('Time (s)', 'FontSize', 40, 'FontWeight', 'bold');
    ylabel('Doppler Value(Hz)', 'FontSize', 40, 'FontWeight', 'bold');
    ylim([-30 30]);
    legend('Before Kalman Filter (Receiver 1)', 'After Kalman Filter (Receiver 1)','Before Kalman Filter (Receiver 2)', 'After Kalman Filter (Receiver 2)', 'FontSize', 25, 'FontWeight', 'bold','Location','northeast');
    % 设置坐标轴的字体大小和加粗
    set(gca,  'FontSize', 40,'FontWeight', 'bold','LineWidth',2,'BoxStyle','full');
    grid on;
    box on;
    set(gcf, 'Position', get(0, 'Screensize')); % 将图形窗口最大化
    saveas(fig_doppler_kf,fullfile(fig_data_folder, ...
    [fig, '_Doppler_Kalman.png']))

end

