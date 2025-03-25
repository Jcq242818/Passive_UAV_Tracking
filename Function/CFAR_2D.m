function [resp1,resp2,detections_1,detections_2,rangeIndx_min,rangeIndx_max,dopplerIndx_min,dopplerIndx_max, ...
    CFAR_th,band_size]= CFAR_2D(CFAR_th,band_size,plot_A_DT_1,plot_A_DT_2,max_DFS,max_time)
       
            GuardBandSize =  band_size ;
            TrainingBandSize = band_size;
            cfar2D = phased.CFARDetector2D('GuardBandSize',GuardBandSize,'TrainingBandSize',TrainingBandSize,...
                'ProbabilityFalseAlarm',CFAR_th);
            resp1=plot_A_DT_1;
            %rangeIndx筛选多普勒范围
            rangeIndx_min =  1 + GuardBandSize + TrainingBandSize;
            rangeIndx_max =  max_DFS - (GuardBandSize + TrainingBandSize);
            %dopplerIndx筛选时间范围
            dopplerIndx_min= 1 + GuardBandSize + TrainingBandSize;
            dopplerIndx_max= max_time -  2*(GuardBandSize + TrainingBandSize);
            [columnInds,rowInds] = meshgrid(dopplerIndx_min:dopplerIndx_max,...
             rangeIndx_min:rangeIndx_max);
            CUTIdx = [rowInds(:) columnInds(:)]';
            detections_1 = cfar2D(resp1,CUTIdx);

            %%CFAR--Sur2
            cfar2D = phased.CFARDetector2D('GuardBandSize',GuardBandSize,'TrainingBandSize',TrainingBandSize,...
              'ProbabilityFalseAlarm',CFAR_th);
            resp2=plot_A_DT_2;
            %rangeIndx筛选多普勒范围
            rangeIndx_min= 1 + GuardBandSize + TrainingBandSize;
            rangeIndx_max= max_DFS - (GuardBandSize + TrainingBandSize);
            %dopplerIndx筛选时间范围
            dopplerIndx_min= 1 + GuardBandSize + TrainingBandSize;
            dopplerIndx_max= max_time -  2*(GuardBandSize + TrainingBandSize);
            [columnInds,rowInds] = meshgrid(dopplerIndx_min:dopplerIndx_max,...
              rangeIndx_min:rangeIndx_max);
            CUTIdx = [rowInds(:) columnInds(:)]';
            %CFAR检测结果
            detections_2 = cfar2D(resp2,CUTIdx);
end

