function [xy_BS1,xy_BS2,xy_Rx1,xy_Rx2,XY_gps] = Read_GPS_data(file_name)
% 使得命令窗口中的输出更加紧凑，减少不必要的空白行。
format compact; 
addpath(genpath('parser')); 
rng(13);
%% Satellite
filename_map = './Map_Fig/map.jpg';
%三个基站的经纬度坐标-- don't modify it!!!
latlon_BS1_1850 =  [22.60443, 113.99654];
latlon_BS2_1870 =  [22.602215,113.997983];
%RX经纬度坐标--GPS data
%RX1
latlon_Rx1(1,1) = DDMM2N('2236.25588625');
latlon_Rx1(1,2) = DDDMM2N('11359.90378660');
%RX2
latlon_Rx2(1,1) = DDMM2N('2236.24470322');
latlon_Rx2(1,2) = DDDMM2N('11359.91499679');

% 图像左上角和右下角的经纬度
latlon_map = [22.60864,113.99258; 22.59725,114.00424]; 
dxy = [1190,1270]; % map size [m]

mapInfo = imfinfo(filename_map);
size_map = [mapInfo.Height,mapInfo.Width];
%图像纬度之差
latlim = latlon_map([2,1],1);
%图像经度之差
lonlim = latlon_map([1,2],2);

%将地理坐标（经纬度）转换为图像内的内在坐标（像素坐标）
R_G2I = georefcells(latlim,lonlim,size_map);
[pix_BS1(1),pix_BS1(2)] = geographicToIntrinsic(R_G2I,latlon_BS1_1850(1),latlon_BS1_1850(2));
[pix_BS2(1),pix_BS2(2)] = geographicToIntrinsic(R_G2I,latlon_BS2_1870(1),latlon_BS2_1870(2));
[pix_Rx1(1),pix_Rx1(2)] = geographicToIntrinsic(R_G2I,latlon_Rx1(1),latlon_Rx1(2));
[pix_Rx2(1),pix_Rx2(2)] = geographicToIntrinsic(R_G2I,latlon_Rx2(1),latlon_Rx2(2));

%地图的世界坐标系 X,Y 范围进行调整，使其相对于接收器(原点)的位置进行对齐。
xlim_W = [0,dxy(1)]-dxy(1)*(latlon_Rx1(2)-lonlim(1))/diff(lonlim);
ylim_W = [0,dxy(2)]-dxy(2)*(latlon_Rx1(1)-latlim(1))/diff(latlim);

%将图像的内在坐标（像素坐标）转换为世界坐标(米为单位,且RX为原点)
R_I2W = imref2d(size_map,xlim_W,ylim_W);
[xy_BS1(1),xy_BS1(2)] = intrinsicToWorld(R_I2W,pix_BS1(1),pix_BS1(2));
[xy_BS2(1),xy_BS2(2)] = intrinsicToWorld(R_I2W,pix_BS2(1),pix_BS2(2));
[xy_Rx1(1),xy_Rx1(2)] = intrinsicToWorld(R_I2W,pix_Rx1(1),pix_Rx1(2));
[xy_Rx2(1),xy_Rx2(2)] = intrinsicToWorld(R_I2W,pix_Rx2(1),pix_Rx2(2));
% xy_BS1
% xy_BS2
% xy_Rx1
% xy_Rx2
%% Read GPS and process the Ground_Truth data of the UAV
folder_path = fullfile('./Dataset/GPS_log/');
filename_gps = fullfile(folder_path, [file_name,'.txt']);
data_gps_str = readmatrix(filename_gps, ...
    'FileType','delimitedtext', ...
    'Delimiter',',', ...
    'Range',[1,1], ...
    'OutputType','string');
%提取读取数据的第 2, 3, 5, 10 列，并转置。
data_gps_str = data_gps_str(:,[2,3,5,10])';
n_time = size(data_gps_str,2);
data_gps = zeros(4,n_time);
for i = 1:length(data_gps_str)
    data_gps(1,i) = HHMMSS2N(data_gps_str(1,i));
    data_gps(2,i) = DDMM2N(data_gps_str(2,i));
    data_gps(3,i) = DDDMM2N(data_gps_str(3,i));
end
data_gps(4,:) = str2double(data_gps_str(4,:));

%GroundTruth坐标轨迹--XYZ_gps
XY_gps = zeros(2,n_time);
%经度纬度转像素
[XY_gps(1,:),XY_gps(2,:)] = geographicToIntrinsic(R_G2I,data_gps(2,:),data_gps(3,:));
%像素转以RX为坐标原点的世界坐标系(单位:米)
[XY_gps(1,:),XY_gps(2,:)] = intrinsicToWorld(R_I2W,XY_gps(1,:),XY_gps(2,:));
end



    