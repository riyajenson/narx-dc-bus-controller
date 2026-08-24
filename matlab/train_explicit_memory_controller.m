function train_explicit_memory_controller()
%TRAIN_EXPLICIT_MEMORY_CONTROLLER Train a non-autoregressive neural controller.

cfg = project_config();
assert(isfile(cfg.preparedDataFile), "Run prepare_dataset first.");
data = load(cfg.preparedDataFile, "piInput", "sensed", "piOutput");

[features, targets, sampleIndex, featureNames] = ...
    build_explicit_memory_features(data.piInput, data.sensed, data.piOutput);
rng(cfg.randomSeed, "twister");

net = fitnet([24 12], "trainbr");
net.name = "Explicit-Memory DC-Bus Neural Controller";
net.performFcn = "mse";
net.divideFcn = "divideblock";
net.divideParam.trainRatio = cfg.trainRatio;
net.divideParam.valRatio = cfg.validationRatio;
net.divideParam.testRatio = cfg.testRatio;
net.trainParam.epochs = 300;
net.trainParam.max_fail = 12;

[net, trainingRecord] = train(net, features, targets);

modelFile = fullfile(cfg.rootDir, "models", ...
    "explicit_memory_controller.mat");
architecture.hiddenSizes = [24 12];
architecture.shortWindow = 4;
architecture.longWindow = 32;
architecture.featureNames = featureNames;
architecture.sampleTime = "one normalized sample";
architecture.feedbackUsesPredictedOutput = false;
save(modelFile, "net", "trainingRecord", "architecture", "sampleIndex");
fprintf("Saved explicit-memory controller to %s\n", modelFile);
end
