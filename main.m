close all;
clc;
tic
%% 1.Parameter config
% 文件读写参数
folder_path_sur = fullfile('Dataset','Processed_raw_data');
file_list_sur = dir(folder_path_sur);

% 过滤掉文件夹，只保留文件
file_list_sur = file_list_sur(~[file_list_sur.isdir]);

% 去除.和..条目
file_list_sur = file_list_sur(~ismember({file_list_sur.name}, {'.', '..'}));
total_files_sur = length(file_list_sur);
file_count_sur = 0;

% 开始循环处理所有数据
for idx_sur = 1:numel(file_list_sur)
    file_count_sur = file_count_sur + 1;
    disp(['处理到Processed_raw_data的第', num2str(file_count_sur), '/', num2str(total_files_sur), ...
            '个数据文件: ', file_list_sur(idx_sur).name]);
    skip_flag_sur = input('输入1处理这个数据，输入2跳过这个数据\n', 's');
    fig_temp  = file_list_sur(idx_sur).name; 
    if strcmp(skip_flag_sur, '1') 
            CIT = 0.5;
            fre_lag = 0;
            time_lag = 4;
            chan_num_total = 2;
            f_s = 5e6;
            N_slide = 10;
            T_slide = CIT / N_slide; %每0.05s数据移动
            max_dop = 50; %最大Doppler频率
            step_dop = 1/CIT; %多普勒分辨率
            array_Doppler_frequency = -max_dop:step_dop:max_dop;
            clear data_receiver1 data_receiver2;
            [~, fig_name, ~] = fileparts(file_list_sur(idx_sur).name);
            %储存CFAR图片结果的路径
            fig = fig_name;
            fig_data_folder = fullfile('Figure', fig_name);
            if ~exist(fig_data_folder, 'dir')
                    mkdir(fig_data_folder);
            end
            %% 2.Read the GPS file
            data_file_name = extractBefore(file_list_sur(idx_sur).name, '.mat');
            [xy_BS1,xy_BS2,xy_Rx1,xy_Rx2,XY_gps] = Read_GPS_data(data_file_name);    
            
            % Load mat文件       
            % 构建 fig.mat 文件路径
            matFilePath = fullfile( './Dataset/Processed_raw_data/',[fig, '.mat']);

            % 检查文件是否存在并加载
            if exist(matFilePath, 'file')
                load(matFilePath);
            else
                error('File %s not found.', matFilePath);
            end

            %% 3.CC and CAF
            [plot_A_DT_1,~] = CC_CAF('Receiver1',data_receiver1,fre_lag, time_lag, CIT,f_s, ...
                T_slide,array_Doppler_frequency,N_slide,max_dop,step_dop,fig_name,fig_data_folder);
            [plot_A_DT_2,array_start_time] = CC_CAF('Receiver2',data_receiver2, ...
                fre_lag, time_lag, CIT,f_s,T_slide,array_Doppler_frequency,N_slide, ...
                max_dop,step_dop,fig_name,fig_data_folder); 
            
            %% 4.2D-CFAR       
            % 构建 fig.mat 文件路径
            matFilePath = fullfile('./Processing Parameters', [fig, '.mat']);

            % 检查文件是否存在并加载
            if exist(matFilePath, 'file')
                load(matFilePath);
            else
                error('File %s not found.', matFilePath);
            end 

            [max_time, max_DFS]  = size(plot_A_DT_1');
            [resp1,resp2,detections_1,detections_2,rangeIndx_min,rangeIndx_max,dopplerIndx_min,dopplerIndx_max, ...
                CFAR_th,band_size] = CFAR_2D(CFAR_th,band_size,plot_A_DT_1,plot_A_DT_2,max_DFS,max_time); 

            %% 5.Path-Matching
            [aligned_DF1_smoothed,aligned_DF2_smoothed] = Path_Matching(resp1,resp2,detections_1, ...
                detections_2,rangeIndx_min,rangeIndx_max,dopplerIndx_min,dopplerIndx_max, ...
                step_dop,T_slide,fig_data_folder,fig, ...  
                threshold_doppler1,threshold_doppler2,loess_value,spline_value,lamda1,lamda2);

            initial_position = [XY_gps(1,1),XY_gps(2,1)];

            %% 6.Rocover trajectory
            Location = Recover_Trajectory(aligned_DF1_smoothed,aligned_DF2_smoothed,array_start_time,T_slide,...            
            xy_BS1,xy_BS2,xy_Rx1,xy_Rx2,initial_position);

            %% 7.Plot Trajectory in Satellite Map
            Plot_Traj_in_Map(Location,XY_gps,fig_data_folder,fig);
                
    elseif  strcmp(skip_flag_sur, '2')
        continue;
    end
end
toc
