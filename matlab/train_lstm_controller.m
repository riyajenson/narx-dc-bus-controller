function train_lstm_controller()
%TRAIN_LSTM_CONTROLLER Train a sequence-to-sequence stateful controller.

cfg = project_config();
assert(isfile(cfg.preparedDataFile), "Run prepare_dataset first.");
data = load(cfg.preparedDataFile, "piInput", "sensed", "piOutput");
rng(cfg.randomSeed, "twister");

sequenceLength = 512;
[X, Y, ranges] = build_lstm_sequences(data.piInput, data.sensed, ...
    data.piOutput, sequenceLength);
sequenceCount = numel(X);
trainEnd = floor(cfg.trainRatio * sequenceCount);
validationEnd = floor((cfg.trainRatio + cfg.validationRatio) * sequenceCount);
assert(trainEnd >= 1 && validationEnd > trainEnd && ...
    validationEnd < sequenceCount, "Invalid chronological sequence split.");

trainIndices = 1:trainEnd;
validationIndices = trainEnd+1:validationEnd;
testIndices = validationEnd+1:sequenceCount;

trainingInputs = cat(2, X{trainIndices});
trainingTargets = cat(2, Y{trainIndices});
normalization.inputMean = mean(trainingInputs, 2);
normalization.inputStd = std(trainingInputs, 0, 2);
normalization.inputStd(normalization.inputStd < eps) = 1;
normalization.targetMean = mean(trainingTargets, 2);
normalization.targetStd = std(trainingTargets, 0, 2);
if normalization.targetStd < eps
    normalization.targetStd = 1;
end

for k = 1:sequenceCount
    X{k} = (X{k} - normalization.inputMean) ./ normalization.inputStd;
    Y{k} = (Y{k} - normalization.targetMean) ./ normalization.targetStd;
end

XTrain = X(trainIndices);
YTrain = Y(trainIndices);
XValidation = X(validationIndices);
YValidation = Y(validationIndices);
XTest = X(testIndices);
YTest = Y(testIndices);

layers = [ ...
    sequenceInputLayer(2, "Name", "controller_inputs")
    lstmLayer(64, "OutputMode", "sequence", "Name", "stateful_memory")
    fullyConnectedLayer(32, "Name", "nonlinear_projection")
    tanhLayer("Name", "projection_activation")
    fullyConnectedLayer(1, "Name", "controller_output")
    regressionLayer("Name", "regression")];

options = trainingOptions("adam", ...
    "MaxEpochs", 80, ...
    "MiniBatchSize", 8, ...
    "InitialLearnRate", 1e-3, ...
    "GradientThreshold", 1, ...
    "Shuffle", "never", ...
    "ValidationData", {XValidation, YValidation}, ...
    "ValidationFrequency", 5, ...
    "ValidationPatience", 10, ...
    "Verbose", true, ...
    "Plots", "training-progress", ...
    "ExecutionEnvironment", "auto");

lstmNet = trainNetwork(XTrain, YTrain, layers, options);

modelFile = fullfile(cfg.rootDir, "models", "lstm_controller.mat");
metadata.sequenceLength = sequenceLength;
metadata.warmupSamples = 64;
metadata.inputs = ["PI Input", "Vdc Sensed"];
metadata.output = "PI Output";
metadata.hasOutputFeedback = false;
metadata.timeUnit = "normalized sample";
save(modelFile, "lstmNet", "normalization", "metadata", "ranges", ...
    "trainIndices", "validationIndices", "testIndices", "XTest", "YTest");
fprintf("Saved LSTM controller to %s\n", modelFile);
end
