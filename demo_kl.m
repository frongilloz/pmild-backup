%% Demo to run the bandselectKL() form of dimensionality reduction, and 
% then run pMILd

%% Load in the data (RAW-> to be reduced via KL) 
% Class 1
g2_L_st = load("geno2_L_array_8_28_19.mat");
% Unpack the struct
g2_L_array = getfield(g2_L_st, 'geno2_L_cell_array');

% Class 2
g4_L_st = load("geno4_L_array_8_28_19.mat");
% Unpack the struct
g4_L_array = getfield(g4_L_st, 'geno4_L_cell_array');

%% Run KL
% The idea is to find the major humps in this plot
% But avoid to select neighboring peaks because neighboring features provided similar information
% maxN_feature the larger the better. Since you have 24180 samples for one class. 
% I think you can set maxN_feature = 20 or even higher

% bandselectKL(bag_p,bag_n,min_gap,maxN_feature)
% 10x: 20,25
% 8x: 25,25
[bag_p_bandselect, bag_n_bandselect, bandselect] = bandselectKL(g2_L_array,g4_L_array,25,25);


%% Outputs
% bag_p_bandselect: 1-by-N_p, cell, where N_p is the number of positive bags. For each
% element of cell, d_reduced-by-n_i, where d_reduced is the new dimensionality and
% n_i is the number of samples in the i-th positive bag. Similar for
% bag_n_bandselect, negative bags

% bandselect: selected features, 1-by-d_reduced. 

%% Opt1: Split 
%% Reduce the produced KL bags (1x4) into 5x5 many bags
% c2_train_bag = {};
% c4_train_bag = {};
% 
% % Break into 5x5
% %Need to perform the split for each node of the (1x4 bag_p_bandselect)
% c2_train_bag = break_kl_bags(bag_p_bandselect);
% 
% % Repeat for negative class
% c4_train_bag = break_kl_bags(bag_n_bandselect);
% 
% %% Now split into 5x5, need to make a format compatible with the pmild alg
% % Train on 1,2,4
% c2_train_bags = [c2_train_bag{1} c2_train_bag{2} c2_train_bag{4} ];
% c4_train_bags = [c4_train_bag{1} c2_train_bag{2} c4_train_bag{4} ];
% 
% % Test on 3ss
% c2_test_bags = [ c2_train_bag{3} ];
% c4_test_bags = [ c4_train_bag{3} ]; 

%% Opt 2: Split without splitting to 5x5
c2_train_bags = [{bag_p_bandselect{1}} {bag_p_bandselect{4}} ];
c4_train_bags = [{bag_n_bandselect{1}} {bag_n_bandselect{4}} ];

%% pmild Training
disp('run pMILd...')

result_pmild = pmild(c2_train_bags,c4_train_bags,2,2,0.5,0);

disp('Training Complete')

% Note: Received "retry on background x100" errors

%% Test (Not Done Yet)

% convert to class format supported by testing function
for t = 1:size(c2_test_bags,1)
    % For every row of the test bag, store it into a single col class
    % struct
    data_test(t).class = c2_test_bags(t,:);
end

% Run the testing method; Class 2
[result_pmld_test_mean,result_pmld_test_max] = pmild_testing_multi_fix(data_test,result_pmild);


%% Supporting Functions
% Reduce the KL produced bags into a 5x5 cell array for training/testing
function train_bag = break_kl_bags(bag_bandselect)
    train_bag = {};

    % Break into 5x5
    %Need to perform the split for each node of the (1x4 bag_p_bandselect)
    for i = 1:4
        % Unpack the current
        curr_p_bag = bag_bandselect{i};

        % Break into 5x5
        curr_p_train_bags = n_bag_grid_split_5_v2(curr_p_bag,5);

        % Append to cell array for training
        train_bag{i} = curr_p_train_bags;
    end
end
