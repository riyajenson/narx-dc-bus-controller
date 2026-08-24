function cfg = project_config()
%PROJECT_CONFIG Central configuration for the NARX controller project.

matlabDir = fileparts(mfilename("fullpath"));
cfg.rootDir = fileparts(matlabDir);
cfg.rawDataFile = fullfile(cfg.rootDir, "data", "raw", "dc_bus_data.xlsx");
cfg.preparedDataFile = fullfile(cfg.rootDir, "data", "processed", "dc_bus_prepared.mat");
cfg.modelFile = fullfile(cfg.rootDir, "models", "narx_controller.mat");
cfg.resultsDir = fullfile(cfg.rootDir, "results");

cfg.randomSeed = 42;
cfg.inputDelays = 1:2;
cfg.feedbackDelays = 1:2;
cfg.hiddenSizes = [16 8];
cfg.trainRatio = 0.70;
cfg.validationRatio = 0.15;
cfg.testRatio = 0.15;
cfg.maxSamples = 30000;
cfg.outputMin = -9.33386;
cfg.outputMax = 10.0503;
end
