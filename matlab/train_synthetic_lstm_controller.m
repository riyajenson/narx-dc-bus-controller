function train_synthetic_lstm_controller()
%TRAIN_SYNTHETIC_LSTM_CONTROLLER Train on randomized expert episodes.

cfg = project_config();
dataFile = fullfile(cfg.rootDir, "data", "processed", ...
    "synthetic_dc_bus_training.mat");
assert(isfile(dataFile), "Run generate_synthetic_training_data first.");
data = load(dataFile, "inputs", "targets", "metadata");
rng(cfg.randomSeed, "twister");

episodeCount = numel(data.inputs);
trainEnd = floor(0.70 * episodeCount);
validationEnd = floor(0.85 * episodeCount);
trainIndices = 1:trainEnd;
validationIndices = trainEnd+1:validationEnd;
testIndices = validationEnd+1:episodeCount;

trainingInputs = cat(2, data.inputs{trainIndices});
trainingTargets = cat(2, data.targets{trainIndices});
normalization.inputMean = mean(trainingInputs, 2);
normalization.inputStd = std(trainingInputs, 0, 2);
normalization.inputStd(normalization.inputStd < eps) = 1;
normalization.targetMean = mean(trainingTargets, 2);
normalization.targetStd = std(trainingTargets, 0, 2);
if normalization.targetStd < eps
    normalization.targetStd = 1;
end

inputs = data.inputs;
targets = data.targets;
for k = 1:episodeCount
    inputs{k} = (inputs{k} - normalization.inputMean) ./ ...
        normalization.inputStd;
    targets{k} = (targets{k} - normalization.targetMean) ./ ...
        normalization.targetStd;
end

XTrain = inputs(trainIndices);
YTrain = targets(trainIndices);
XValidation = inputs(validationIndices);
YValidation = targets(validationIndices);
XTest = inputs(testIndices);
YTest = targets(testIndices);

layers = [ ...
    sequenceInputLayer(3, "Name", "controller_inputs")
    lstmLayer(64, "OutputMode", "sequence", "Name", "stateful_memory")
    fullyConnectedLayer(32, "Name", "nonlinear_projection")
    tanhLayer("Name", "projection_activation")
    fullyConnectedLayer(1, "Name", "normalized_control_output")
    regressionLayer("Name", "regression")];

options = trainingOptions("adam", ...
    "MaxEpochs", 60, ...
    "MiniBatchSize", 12, ...
    "InitialLearnRate", 1e-3, ...
    "LearnRateSchedule", "piecewise", ...
    "LearnRateDropPeriod", 20, ...
    "LearnRateDropFactor", 0.5, ...
    "GradientThreshold", 1, ...
    "Shuffle", "every-epoch", ...
    "ValidationData", {XValidation, YValidation}, ...
    "ValidationFrequency", 10, ...
    "ValidationPatience", 12, ...
    "Verbose", true, ...
    "Plots", "training-progress", ...
    "ExecutionEnvironment", "auto");

syntheticLstmNet = trainNetwork(XTrain, YTrain, layers, options);
modelFile = fullfile(cfg.rootDir, "models", ...
    "synthetic_lstm_controller.mat");
modelMetadata = data.metadata;
modelMetadata.inputs = ["Vdc reference", "Vdc sensed", "voltage error"];
modelMetadata.output = "controller command";
modelMetadata.hasPredictedOutputFeedback = false;
modelMetadata.warmupSamples = 40;
save(modelFile, "syntheticLstmNet", "normalization", "modelMetadata", ...
    "XTest", "YTest", "testIndices");
fprintf("Saved synthetic-data LSTM controller to %s\n", modelFile);
end
