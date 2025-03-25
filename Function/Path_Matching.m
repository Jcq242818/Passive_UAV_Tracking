function [aligned_DF1_smoothed,aligned_DF2_smoothed] = Path_Matching(resp1,resp2,detections_1,detections_2,rangeIndx_min,...
    rangeIndx_max,dopplerIndx_min,dopplerIndx_max,step_dop,T_slide,fig_data_folder,fig, ...
    threshold_doppler1,threshold_doppler2,loess_value,spline_value,lamda1,lamda2)
        
        Map_1 = zeros(size(resp1));%初始化映射矩阵，resp1的size为初始的CAF矩阵的size
        Map_2 = zeros(size(resp2));
        Map_1(rangeIndx_min:rangeIndx_max,dopplerIndx_min:dopplerIndx_max) = ...
        reshape(double(detections_1),[rangeIndx_max-rangeIndx_min+1,dopplerIndx_max-dopplerIndx_min+1]);
        Map_2(rangeIndx_min:rangeIndx_max,dopplerIndx_min:dopplerIndx_max) = ...
        reshape(double(detections_2),rangeIndx_max-rangeIndx_min+1,dopplerIndx_max-dopplerIndx_min+1);

        %下面的过程是为了得到CFAR后两个散点图的趋势线。
        CFAR2Doppler_1 = zeros(size(resp1,1)*size(resp1,2),2); 
        CFAR2Doppler_2 = zeros(size(resp1,1)*size(resp1,2),2);
        count1 = 0;
        count2 = 0;

        for i = 1:size(resp1,1)
            for j = 1:size(resp1,2)

                if Map_1(i,j) == 1
                    count1 = count1 + 1;
                    CFAR2Doppler_1(count1,1) = j;
                    CFAR2Doppler_1(count1,2) = Row2Df(i,step_dop);
                end
                

                if Map_2(i,j) == 1
                    count2 = count2 + 1;
                    CFAR2Doppler_2(count2,1) = j;
                    CFAR2Doppler_2(count2,2) = Row2Df(i,step_dop);
                end
                
            end
        end
        
        %这里是对CFAR2Doppler_1和CFAR2Doppler_2进行截断的操作，即只保留前面赋了值的行。
        CFAR2Doppler_1 = CFAR2Doppler_1(1:count1,:);
        CFAR2Doppler_2 = CFAR2Doppler_2(1:count2,:);

        %利用散点图的趋势线来找出离群值，并将其设置为0
        trend_curve_1 = Trendcurve(CFAR2Doppler_1,loess_value,spline_value);
        trend_curve_2 = Trendcurve(CFAR2Doppler_2,loess_value,spline_value);

        flag_1 = min(CFAR2Doppler_1);
        flag_2 = min(CFAR2Doppler_2);

        for i = rangeIndx_min:rangeIndx_max
            for j = dopplerIndx_min:dopplerIndx_max

                if Map_1(i,j) == 1
                    Map_1_resultDF = Row2Df(i,step_dop);
                    if abs(Map_1_resultDF - trend_curve_1(j - flag_1(1) + 1)) >  threshold_doppler1
                        Map_1(i,j) = 0;
                    end
                end

                if Map_2(i,j) == 1
                    Map_2_resultDF = Row2Df(i,step_dop);
                    if abs(Map_2_resultDF - trend_curve_2(j - flag_2(1) + 1)) >  threshold_doppler2
                        Map_2(i,j) = 0;
                    end
                end
                
            end
        end

        % 找到所有非零列的索引
        nonzero_cols_1 = find(any(Map_1, 1));
        
        % 如果矩阵中没有非零列，返回空
        if isempty(nonzero_cols_1)
        first_nonzero_col_1 = [];
        last_nonzero_col_1 = [];
        else
        % 第一个非零列的索引
        first_nonzero_col_1 = nonzero_cols_1(1);
        
        % 最后一个非零列的索引
        last_nonzero_col_1 = nonzero_cols_1(end);
        end

        % 找到所有非零列的索引
        nonzero_cols_2 = find(any(Map_2, 1));
        
        % 如果矩阵中没有非零列，返回空
        if isempty(nonzero_cols_2)
        first_nonzero_col_2 = [];
        last_nonzero_col_2 = [];
        else
        % 第一个非零列的索引
        first_nonzero_col_2 = nonzero_cols_2(1);
        
        % 最后一个非零列的索引
        last_nonzero_col_2 = nonzero_cols_2(end);
        end

        endCol_first_1 = 0;
        endCol_first_2 = 0;
        % resultDFList_1即存放路径匹配后每个时刻平滑的多普勒解
        resultDFList_1 = zeros(1,dopplerIndx_max-dopplerIndx_min+1);
        resultDFList_2 = zeros(1,dopplerIndx_max-dopplerIndx_min+1);
        % 提取和处理第一行时间时候的多普勒列
        lastCol = Map_1(:,dopplerIndx_min);
        lastCol_2 = Map_2(:,dopplerIndx_min);
        % 利用find(lastCol ~= 0)寻找非0列的列index并记录到nonZeroRow中
        nonZeroRow = find(lastCol ~= 0);
        nonZeroRow_2 = find(lastCol_2 ~= 0);

        if isempty(nonZeroRow) % If the first moment is 0, you have to look later
            for i = dopplerIndx_min+1 : dopplerIndx_max
                    testCol_first = Map_1(:,i); %第i列的多普勒

                    testNonZeroRow_first = find(testCol_first ~= 0);
                    if isempty(testNonZeroRow_first) %如果检测到的列还是全0, 那么跳过这次循环，i+1
                        continue
                    else %如果检测到的第一个非0列, endCol_first_1赋值为该非0列的列index
                        endCol_first_1 = i;
                        Doppler_strength_1 = 10^(resp1(testNonZeroRow_first,i)./20);
                        Doppler_strength_1 = Doppler_strength_1./sum(Doppler_strength_1);
                        endRow_first_1 = mean(Doppler_strength_1.*Row2Df(testNonZeroRow_first,step_dop));                          
                        break
                    end
            end
            resultDF = endRow_first_1;
            resultDFList_1(endCol_first_1-dopplerIndx_min+1) = resultDF;
            resultDFList_1(1:endCol_first_1-dopplerIndx_min) = [];
        else
            endCol_first_1 = dopplerIndx_min;
            resultDF = mean(Row2Df(nonZeroRow,step_dop));
            resultDFList_1(1) = resultDF;
        end

        if isempty(nonZeroRow_2) % If the first moment is 0, you have to look later
            for i = dopplerIndx_min+1 : dopplerIndx_max
                    testCol_first = Map_2(:,i);
                    testNonZeroRow_first = find(testCol_first ~= 0);
                    if isempty(testNonZeroRow_first)
                        continue
                    else
                        endCol_first_2 = i;
                        Doppler_strength_2 = 10.^(resp2(testNonZeroRow_first,i)./20);
                        Doppler_strength_2 = Doppler_strength_2./sum(Doppler_strength_2);
                        endRow_first_2 = mean(Doppler_strength_2.*Row2Df(testNonZeroRow_first,step_dop));                        
                        break
                    end
            end
            resultDF = endRow_first_2; %%Insert 0 Doppler
            resultDFList_2(endCol_first_2-dopplerIndx_min+1) = resultDF;
            resultDFList_2(1:endCol_first_2-dopplerIndx_min) = [];
        else
            endCol_first_2 = dopplerIndx_min;
            resultDF = mean(Row2Df(nonZeroRow_2,step_dop));
            resultDFList_2(1) = resultDF;
        end

        endCol_1 = 0;
        loop_end_flag_1 = false;
        % 即从刚才检测到的第一个非零列的列index到最后一列进行遍历
        for i = endCol_first_1+1 : dopplerIndx_max %12 to 379
            %这里可能会有bug? 应该改成if i < endCol_1+2
            if i < endCol_1+1
                continue
            end

            thisCol = Map_1(:,i);
            % 继续找非0列
            nonZeroRow = find(thisCol ~= 0);
            if isempty(nonZeroRow)
                %如果最后一列是全零列就不要往后找了，直接把该列多普勒赋值为0
                if i == dopplerIndx_max
                    resultDFList_1(i-endCol_first_1+1) = [];
                    break
                end
                startCol = i;
                % Find forwad until there exists a unempty column
                for j = i+1 : dopplerIndx_max
                    testCol = Map_1(:,j);
                    testNonZeroRow = find(testCol ~= 0);
                    if isempty(testNonZeroRow)
                        if j == dopplerIndx_max
                            %如果在往后找的时候找到了最后一列，那么把之前所有全零列的多普勒全部赋值为0
                            resultDFList_1((i-endCol_first_1+1):(j-endCol_first_1+1)) = [];
                            loop_end_flag_1 = true;
                            break
                        end
                        continue
                    else %找到了下一个非零列
                        endCol_1 = j-1;
                        % 下一个非零列对应的多普勒值是该列所有行对应的多普勒值的平均值

                        Doppler_strength_1_tempolate= 10.^(resp1( testNonZeroRow,j)./20);
                        Doppler_strength_1_tempolate = Doppler_strength_1_tempolate./sum(Doppler_strength_1_tempolate);

                        temp =  Doppler_strength_1_tempolate .*abs(Row2Df(testNonZeroRow,step_dop));
                        [miniRow_tempolate, miniCol_tempolate] = find(temp==max(temp));
                        endRow = Row2Df(testNonZeroRow(miniRow_tempolate(1)),step_dop);
                        
                        break
                    end
                end

                if loop_end_flag_1 == true
                    break
                end
                % 现在我们找到了插值起始点和终点，那我们就可以对这些全0列依次循环进行线性多普勒插值
                slope = (endRow-resultDF)/((endCol_1-startCol+2)*T_slide);
                % 现在遍历循环对检测到区间内每一个全0列依次执行线性插值
                for k = startCol:endCol_1
                    resultDFList_1(k-endCol_first_1+1) =  resultDF + slope*((k-startCol+1)*T_slide);
                end
                resultDF = resultDFList_1(endCol_1-endCol_first_1+1);

            elseif length(nonZeroRow) == 1  %Just one Doppler
                resultDF = Row2Df(nonZeroRow,step_dop);
                resultDFList_1(i-endCol_first_1+1) = resultDF;

            else  %There's multiple Dopplers--Case2
                 Doppler_strength_1_multiple = 10.^(resp1(nonZeroRow,i)./20);
                 Doppler_strength_1_multiple = Doppler_strength_1_multiple./sum(Doppler_strength_1_multiple);
                 resultDF = lamda1*sum(Doppler_strength_1_multiple.*Row2Df(nonZeroRow,step_dop)) + (1 - lamda1)*resultDF;
                 resultDFList_1(i-endCol_first_1+1) = resultDF;
            end
        end

        % Extract and process endCol_first_2+1 st to the last columns for channel 2
        endCol_2 = 0;
        loop_end_flag_2 = false;
        for i = endCol_first_2+1 : dopplerIndx_max %12 to 379
            if i < endCol_2+1
                continue
            end

        thisCol = Map_2(:,i);
        nonZeroRow = find(thisCol ~= 0);
            if isempty(nonZeroRow)
                if i == dopplerIndx_max
                    resultDFList_2(i-endCol_first_2+1) = [];
                    break
                end
                startCol = i;
                % Find forwad until there exists a unempty column
                for j = i+1 : dopplerIndx_max
                    testCol = Map_2(:,j);
                    testNonZeroRow = find(testCol ~= 0);
                    if isempty(testNonZeroRow)
                        if j == dopplerIndx_max
                            resultDFList_2((i-endCol_first_2+1):(j-endCol_first_2+1)) = [];
                            loop_end_flag_2 = true;
                            break
                        end
                        continue
                    else
                        endCol_2 = j-1;
                        
                        Doppler_strength_2_tempolate= 10.^(resp2( testNonZeroRow,j)./20);
                        Doppler_strength_2_tempolate = Doppler_strength_2_tempolate./sum(Doppler_strength_2_tempolate);

                        temp_2 =   Doppler_strength_2_tempolate .*abs(Row2Df(testNonZeroRow,step_dop));
                        [miniRow_tempolate_2, miniCol_tempolate_2] = find(temp_2==max(temp_2));
                        endRow = Row2Df( testNonZeroRow(miniRow_tempolate_2(1)),step_dop);
                        
                        break
                    end
                end

                if loop_end_flag_2 == true
                    break
                end
                slope = (endRow-resultDF)/((endCol_2-startCol+2)*T_slide);
                for k = startCol:endCol_2
                    resultDFList_2(k-endCol_first_2+1) =  resultDF + slope*((k-startCol+1)*T_slide);
                end
                resultDF = resultDFList_2(endCol_2-endCol_first_2+1);

            elseif length(nonZeroRow) == 1  %just one
                resultDF = Row2Df(nonZeroRow,step_dop);
                resultDFList_2(i-endCol_first_2+1) = resultDF;

            else  
                Doppler_strength_2_multiple= 10.^(resp2( nonZeroRow,i)./20);
                Doppler_strength_2_multiple = Doppler_strength_2_multiple./sum(Doppler_strength_2_multiple);
                resultDF = lamda2*sum(Doppler_strength_2_multiple.*Row2Df(nonZeroRow,step_dop)) + (1 - lamda2)*resultDF;
                resultDFList_2(i-endCol_first_2+1) = resultDF;
            end
        end

    % 计算需要删除或保留的列范围，避免重复的条件判断
    col_diff_1 = abs(first_nonzero_col_1 - first_nonzero_col_2);  % 首列差值
    col_diff_2 = abs(last_nonzero_col_1 - last_nonzero_col_2);    % 尾列差值
    
    % 判断首列非零列位置的差异
    if first_nonzero_col_1 > first_nonzero_col_2
        resultDFList_2(1:col_diff_1) = [];  % 删除 resultDFList_2 开头部分
    elseif first_nonzero_col_1 < first_nonzero_col_2
        resultDFList_1(1:col_diff_1) = [];  % 删除 resultDFList_1 开头部分
    end
    
    % 判断尾列非零列位置的差异
    if last_nonzero_col_1 > last_nonzero_col_2
        resultDFList_1(end + 1 - col_diff_2:end) = [];  % 删除 resultDFList_1 末尾部分
    elseif last_nonzero_col_1 < last_nonzero_col_2
        resultDFList_2(end + 1 - col_diff_2:end) = [];  % 删除 resultDFList_2 末尾部分
    end

    
    % 将调整后的结果赋值给 aligned_DF1 和 aligned_DF2
    aligned_DF1 = resultDFList_1;
    aligned_DF2 = resultDFList_2;
        
    %%加卡尔曼滤波平滑, here we can also use the Kalman filter in the MATLAB toolbox
    aligned_DF1_smoothed = KalmanSmoother(aligned_DF1);
    aligned_DF2_smoothed = KalmanSmoother(aligned_DF2);

    plotDopplerWithKalman(aligned_DF1,aligned_DF1_smoothed,aligned_DF2,aligned_DF2_smoothed,fig_data_folder,fig);

end

