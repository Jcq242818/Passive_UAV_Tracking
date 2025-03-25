function Location = Recover_Trajectory(aligned_DF1,aligned_DF2,array_start_time,T_slide,Ptx1,Ptx2,Prx1,Prx2,initial_position)

        maxDF1 = aligned_DF1;
        maxDF2 = aligned_DF2;

        fc1 = 1.850e9;
        fc2 = 1.870e9;
        %光速
        c = 3e8;
        lambda1 = c/fc1;
        lambda2 = c/fc2;

        %物体的初始位置
        xTar = initial_position(1);
        yTar = initial_position(2);

        sensing_time = array_start_time(1:numel(aligned_DF1));
        %存放每一个时刻目标的位置
        xtar = zeros(1,length(sensing_time));
        ytar = zeros(1,length(sensing_time));
        xtar(1) = xTar;
        ytar(1) = yTar;
        %存放方程每一次迭代解的xy方向速度值
        v_xy = zeros(2,length(sensing_time)-1);

        %开始解方程与迭代
        for i = 1:1:length(sensing_time)-1
           
            P = [xtar(i),ytar(i)];
            %PosVel2Dop
            vector_rad1_x = (P(1)-Ptx1(1))./vecnorm(P-Ptx1,2,2) + (P(1)-Prx1(1))./vecnorm(P-Prx1,2,2);
            vector_rad1_y = (P(2)-Ptx1(2))./vecnorm(P-Ptx1,2,2) + (P(2)-Prx1(2))./vecnorm(P-Prx1,2,2);
            DFS_term_1 = -lambda1*maxDF1(i);
            vector_rad2_x = (P(1)-Ptx2(1))./vecnorm(P-Ptx2,2,2) + (P(1)-Prx2(1))./vecnorm(P-Prx2,2,2);
            vector_rad2_y =  (P(2)-Ptx2(2))./vecnorm(P-Ptx2,2,2) + (P(2)-Prx2(2))./vecnorm(P-Prx2,2,2);
            DFS_term_2 = -lambda2*maxDF2(i);
            
            v_xy(1,i) = (DFS_term_1*vector_rad2_y - vector_rad1_y * ...
                DFS_term_2)/(vector_rad1_x * vector_rad2_y - vector_rad1_y * vector_rad2_x);
            v_xy(2,i) = (DFS_term_1*vector_rad2_x - vector_rad1_x * ...
                DFS_term_2)/(vector_rad1_y * vector_rad2_x - vector_rad1_x * vector_rad2_y);

             xtar(i+1) = xtar(i)+v_xy(1,i) * T_slide;
             ytar(i+1) = ytar(i)+v_xy(2,i) * T_slide;
        end
        Location = [xtar;ytar];
    end