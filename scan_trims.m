function [centroid_data_final] = scan_trims(limits,mode,npts,axis,const_fit)
%SCAN_TRIMS Scan trim magnets according to "mode"
    %acceptable modes are
    %'1d_t1'    Scan trim 1 along one axis
    %'1d_t2'    Scan trim 2 along one axis
    %'2d'       Scan trim 1 and trim 2 on a rectangular grid
    %'1d_const  Scan trim 2 along one axis while updating trim 1, requires
    %               <const_fit>
    %'2d_bayes' (NOT READY) Scan trim 1 and trim 2 using Gaussain processes
    %need to add to index depending on if axis is 'x' or 'y'
    if strcmp(axis,'x')
        axis_add = 0;
    elseif strcmp(axis,'y')
        axis_add = 1;
    else
        print('warning axis not allowed!')
    end 

    if strcmp(mode,'1d_t1')
        if length(limits) ~= 2
            error('Error limits array is incorrect size for mode "1d_t1"!')
        else
            %create scan values and storage container for centroid values
            trim_values = linspace(limits(1),limits(2),npts);

            %prepare scan points for do_scan function
            %matrix should be of form [[t1_x t1_y t2_x t2_y],...]
            test_points = zeros(4,length(trim_values));
            test_points(1 + axis_add,:) = trim_values;
        end

    elseif strcmp(mode,'1d_t2')
        if length(limits) ~= 2
            error('Error limits array is incorrect size for mode "1d_t2"!')
        else
            %create scan values and storage container for centroid values
            trim_values = linspace(limits(1),limits(2),npts);

            %prepare scan points for do_scan function
            %matrix should be of form [[t1_x t1_y t2_x t2_y],...]
            test_points = zeros(4,length(trim_values));
            test_points(3 + axis_add,:) = trim_values;
        end

    elseif strcmp(mode,'2d')
        if length(limits) ~= 4
            error('Error limits array is incorrect size for mode "2d"!')
        else
            t1_values = linspace(limits(1),limits(2),npts);
            t2_values = linspace(limits(3),limits(4),npts);

            [X,Y] = meshgrid(t1_values,t2_values);
            test_points = zeros(4,length(X(:).'));
            test_points(1 + axis_add,:) = X(:).';
            test_points(3 + axis_add,:) = Y(:).';    
        end
        
    elseif strcmp(mode,'1d_const')
        % scans trim 2 while t_1 = const_fit(1) + t_2*const_fit(2)
        t2_values   = linspace(limits(1),limits(2),npts);
        temp        = [t2_values*0+1; t2_values];
        t1_values   = const_fit*temp;
        
        test_points = zeros(4,length(t2_values));
        test_points(3 + axis_add,:) = t2_values;
        test_points(1 + axis_add,:) = t1_values;

        
    elseif strcmp(mode,'2d_bayes')
        %search space using gp regression
        centroid_data_final = gp_explore();
        return
    else
        error('Error mode not recognized')
    end

    % need to set other axis to current values
    %flip 0->1 and 1->0
    off_axis_add = mod(axis_add + 1, 2);
    
    %query current beamline setting
    current_setting = get_data();
    test_points(2 + off_axis_add,:) = current_setting(2 + off_axis_add);
    test_points(4 + off_axis_add,:) = current_setting(4 + off_axis_add);
    
    %do the actual scan
    centroid_data = do_scan(test_points);
    
    %clean data such that no centroid values are less than zero
    centroid_data = centroid_data(find(centroid_data(:,5) > 0),:);
    centroid_data_final = centroid_data(find(centroid_data(:,6) > 0),:); 

    
end
