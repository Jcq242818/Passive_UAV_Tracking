function [plot_A_DT,array_start_time] = CC_CAF(data_flag,data_receiver,fre_lag, time_lag, ...
    CIT,f_s,T_slide,array_Doppler_frequency,N_slide,max_dop,step_dop,fig_name,fig_data_folder)
  
     % Multiple-CIT CC Param
     multiple_CC_num = 2;    
     %%%滑动数据
     num_sample = CIT*f_s;
     total_duration = size(data_receiver,2)/f_s;
     array_start_time = 0:T_slide:total_duration-CIT;
     A_TD = zeros(length(array_start_time)-1,length(array_Doppler_frequency));
     %因为刚刚可能裁掉了一些数据，所以不要array_start_time的最后一个index时刻，否则可能会数组越界
     for idx_start_time = 1:length(array_start_time)-1
         % Multiplt CIT CC CAF
         if mod(idx_start_time-1, multiple_CC_num*N_slide) >= N_slide &&...
             mod(idx_start_time-1, multiple_CC_num*N_slide) < multiple_CC_num*N_slide
              continue;  % 跳过当前循环
         end
         %类似于进度条的作用
         if mod(idx_start_time,5) == 1
             fprintf("idx_start_time: %d / %d\n",idx_start_time,length(array_start_time)-1);
         end

         % Multiple CIT CC CAF
         if idx_start_time >= length(array_start_time) - (multiple_CC_num-1)* N_slide ...
                 && mod(idx_start_time-1,multiple_CC_num*N_slide) < N_slide                 
             % Same as Single CIT CC
             temp_ref = data_receiver(1,(round(array_start_time(idx_start_time)*f_s+1)):...
                 (round(array_start_time(idx_start_time)*f_s)+round(CIT*f_s)));

             temp_tar = data_receiver(2,(round(array_start_time(idx_start_time)*f_s+1)): ...
                 (round(array_start_time(idx_start_time)*f_s)+round(CIT*f_s)));

            temp_tar = ClutterCancellation(temp_tar', temp_ref', fre_lag, time_lag, CIT, f_s)';

             temp = fftshift(fft(temp_tar.*conj(temp_ref),num_sample));

              A_TD(idx_start_time,:) ...
                  = temp(num_sample/2+1-max_dop/step_dop:num_sample/2+1+max_dop/step_dop);                  

         else
             temp_ref= data_receiver(1,(round(array_start_time(idx_start_time)*f_s+1)):...
                 (round(array_start_time(idx_start_time)*f_s)+round(multiple_CC_num*CIT*f_s)));

             temp_tar = data_receiver(2,(round(array_start_time(idx_start_time)*f_s+1)): ...
                 (round(array_start_time(idx_start_time)*f_s)+round(multiple_CC_num*CIT*f_s)));

            temp_tar = ClutterCancellation(temp_tar', temp_ref', fre_lag, time_lag, CIT, f_s)';

            % Multiple CIT CC
            temp = temp_tar.*conj(temp_ref);

            for segment = 1:multiple_CC_num
                  temp_fft = fftshift(fft(temp(((segment-1)/multiple_CC_num)*end+1: ...
                      (segment/multiple_CC_num)*end),num_sample));    

                   A_TD(idx_start_time + (segment-1)*N_slide,:) ...
                      =  temp_fft(num_sample/2+1-max_dop/step_dop:num_sample/2+1+max_dop/step_dop);         
            end
         end
     end

      %5.Plot CAF figure
        min_A_TRD = -10;
        max_A_TRD = 0;
        plot_A_DT = abs(rot90(A_TD));
        plot_A_DT = mag2db(plot_A_DT./max(plot_A_DT));   
    
        figure;
        imagesc(array_start_time(1:end-1),array_Doppler_frequency,plot_A_DT);
        xlim([array_start_time(1),array_start_time(end)]);
        yticks(-30:10:30);
        set(gcf, 'Position', [100, 100,400,300]);
        colorbar;
        view(2);
        xlabel('Time (s)', 'FontWeight', 'bold')
        ylabel('Doppler Frequency (Hz)', 'FontWeight', 'bold')
        axis xy;
        colormap('jet');
        caxis([min_A_TRD, max_A_TRD]);
        fig_name = fullfile(fig_data_folder, [fig_name, '_CAF_',data_flag,'.png']);
        saveas(gcf, fig_name);
end