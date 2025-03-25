function Plot_Traj_in_Map(Signal_Processing_Trajectory_data,XY_gps,fig_data_folder,fig)

    fig_map = figure('Position',[100,100,400,300]);
    plot(Signal_Processing_Trajectory_data(1,:), ...
        Signal_Processing_Trajectory_data(2,:), ...
        'Color','r','Marker','.','MarkerSize',6,'DisplayName','Reconstructed Trajectory','LineWidth',2);
    hold on;
    plot(XY_gps(1,:),XY_gps(2,:), ...
            'Color','b','Marker','.','MarkerSize',6,'DisplayName','Ground Truth','LineWidth',2);   
    grid on
    xlabel('X (m)', 'FontWeight', 'bold')
    ylabel('Y (m)', 'FontWeight', 'bold')
    set(gca,'YDir','Normal')
    legend('Location','northeast', 'FontWeight', 'bold');
    hold off;
    box on;
    saveas(fig_map,fullfile(fig_data_folder, ...
            [fig, '_Trajectory.png']));
    
    %% Plot the CDF curve of the estimated Trajectory error
    % 1. 计算每个时间点的误差
    errors = sqrt((XY_gps(1,:) - Signal_Processing_Trajectory_data(1,:)).^2 + ...
    (XY_gps(2,:) - Signal_Processing_Trajectory_data(2,:)).^2);
    % 2. 计算每个误差值的出现次数
    uniqueErrors= unique(errors); % 找到不同的误差值及其索引
    [counts,~] = histcounts(errors, uniqueErrors); % 计算每个误差值的出现次数
    
    % 3. 计算CDF
    sortedErrors = uniqueErrors(2:end); % 删除第一个边界，因为它只是误差的下限
    sortedCounts = counts / sum(counts); % 归一化后得到每个误差值的概率                                             
    cdfValues = cumsum(sortedCounts); % 计算累计概率    
    
    % 绘制CDF
    fig_cdf = figure;
    set(gcf, 'Position', [100, 100,400,300]);
    hold on; 
    
    % 绘制轨迹1的CDF（红色实线）
    plot(sortedErrors, cdfValues, 'r-' ,'LineWidth',2,'DisplayName', 'U-shaped');
    
    % 设置坐标轴标签
    xlabel('Trajectory Error (m)', 'FontWeight', 'bold');
    ylabel('CDF', 'FontWeight', 'bold');
    
    % 添加图例
    legend('Location', 'southeast'); % 图例显示在右下角
    set(gca, 'FontWeight', 'bold');
    
    % 统一设置图形样式
    ylim([0 1]);                     % 固定CDF范围为[0,1]
    yticks(0:0.1:1);
    box on;                          % 显示边框
    grid on;
    hold off;
    saveas(fig_cdf,fullfile(fig_data_folder, ...
            [fig, '_Trajectory_CDF.png']));
end



