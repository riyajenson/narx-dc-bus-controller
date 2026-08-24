function train_narx_controller()
%TRAIN_NARX_CONTROLLER Train a temporally ordered PI-replacement model.

cfg = project_config();
assert(isfile(cfg.preparedDataFile), ...
    "Run prepare_dataset before training.");
load(cfg.preparedDataFile, "inputs", "targets");
rng(cfg.randomSeed, "twister");

netOpen = narxnet(cfg.inputDelays, cfg.feedbackDelays, ...
    cfg.hiddenSizes, "open", "trainbr");
netOpen.name = "NARX DC-Bus PI Replacement";
netOpen.performFcn = "mse";
netOpen.divideFcn = "divideblock";
netOpen.divideParam.trainRatio = cfg.trainRatio;
netOpen.divideParam.valRatio = cfg.validationRatio;
netOpen.divideParam.testRatio = cfg.testRatio;
netOpen.trainParam.epochs = 300;
netOpen.trainParam.max_fail = 12;

[preparedInputs, initialInputStates, initialLayerStates, preparedTargets] = ...
    preparets(netOpen, inputs, {}, targets);

[netOpen, trainingRecord] = train(netOpen, preparedInputs, ...
    preparedTargets, initialInputStates, initialLayerStates);
netClosed = closeloop(netOpen);
netClosed.name = "Closed-Loop NARX DC-Bus Controller";

if ~isfolder(fileparts(cfg.modelFile))
    mkdir(fileparts(cfg.modelFile));
end
save(cfg.modelFile, "netOpen", "netClosed", "trainingRecord", "cfg");
fprintf("Saved trained controller to %s\n", cfg.modelFile);
end
