function T = chooseData(  quick_choice )
% This is a simple function to help select model

% The input value means: selectioning one of the dataset: 
% 'all'
% 'orientation',
% 'space' 

% add path to the model
[currPath, prevPath] = stdnormRootPath();
addpath( genpath( fullfile( currPath, 'models' )))

% dataset is [which_dataset (1-4) | which_roi (V1-V3)];
datasets = [1, 2, 3, 4, 5];
roi_idx = [1,2,3];
ROIs     = {'V1' 'V2' 'V3'};
fittime = 40;

model1 = contrastModel(fittime);
model2 = normStdModel(fittime);
model3 = normVarModel(fittime);

switch quick_choice
    case 'all'
        models   = {'contrast' ,  'normStd', 'normPower', 'SOC', 'ori_surround'};
        model_idx = [ 1, 2, 3, 4, 5 ];
    case 'orientation'
        models   = {model1,  model2, model3};% , 'normPower'};
        model_idx = [ 1, 2, 3];
    case 'space'
        models   = { 'SOC', 'ori_surround'};
        model_idx = [ 4, 5 ];
    case 'data5'
        datasets = [5];
        models   = {model1,  model2, model3};
        model_idx = [ 1, 2, 3];
end


n = length(datasets) * length(ROIs) * length(models);

dataset     = NaN(n,1);
roiNum      = NaN(n,1);
roiName     = cell(n,1);
modelNum    = NaN(n,1);
modelLoader   = cell(n,1);

idx = 0;
for d = 1:length(datasets)
    for r = 1:length(ROIs)
        for m = 1:length(models)
             
            idx = idx+1;
        
            dataset(idx)     = datasets(d);
            roiNum(idx)      = roi_idx(r);
            roiName(idx)     = ROIs(r);
            modelNum(idx)    = model_idx(m);
            modelLoader(idx)   = models(m);

        end
    end
end

T = table(dataset, roiNum, roiName, modelNum, modelLoader);

end
