function cfg = project_config()
%PROJECT_CONFIG Central configuration for the DC-Bus LSTM controller project.

matlabDir = fileparts(mfilename("fullpath"));
cfg.rootDir = fileparts(matlabDir);
cfg.rawDataFile = fullfile(cfg.rootDir, "data", "raw", "dc_bus_data.xlsx");
cfg.preparedDataFile = fullfile(cfg.rootDir, "data", "processed", "dc_bus_prepared.mat");
cfg.resultsDir = fullfile(cfg.rootDir, "results");

cfg.randomSeed = 42;
cfg.trainRatio = 0.70;
cfg.validationRatio = 0.15;
cfg.testRatio = 0.15;
cfg.maxSamples = 30000;
end
