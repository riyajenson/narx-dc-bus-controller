function prepare_simulink_replay()
%PREPARE_SIMULINK_REPLAY Export recorded signals for Simulink validation.
% Time is expressed in sample indices because the source dataset has no
% physical timestamp or documented sample period.

cfg = project_config();
assert(isfile(cfg.preparedDataFile), "Run prepare_dataset first.");
assert(isfile(cfg.modelFile), "Run train_narx_controller first.");

prepared = load(cfg.preparedDataFile, ...
    "errorSignal", "sensed", "piOutput", "stride");
trained = load(cfg.modelFile, "netClosed");

n = numel(prepared.piOutput);
sampleIndex = (0:n-1).';

% From Workspace accepts structures with time and signals fields. The NARX
% input is a two-element vector: [voltage error; sensed DC-bus voltage].
narxReplayInput.time = sampleIndex;
narxReplayInput.signals.values = ...
    [prepared.errorSignal(:), prepared.sensed(:)];
narxReplayInput.signals.dimensions = 2;

piReplayTarget.time = sampleIndex;
piReplayTarget.signals.values = prepared.piOutput(:);
piReplayTarget.signals.dimensions = 1;

netClosed = trained.netClosed;
replayMetadata.sampleTime = 1;
replayMetadata.timeUnit = "sample index";
replayMetadata.sourceStride = prepared.stride;
replayMetadata.warning = ...
    "Replay validation only; no physical sample period or plant was supplied.";

replayFile = fullfile(cfg.rootDir, "data", "processed", ...
    "simulink_replay_data.mat");
save(replayFile, "narxReplayInput", "piReplayTarget", ...
    "netClosed", "replayMetadata");

assignin("base", "narxReplayInput", narxReplayInput);
assignin("base", "piReplayTarget", piReplayTarget);
assignin("base", "netClosed", netClosed);
assignin("base", "replayMetadata", replayMetadata);

fprintf("Prepared %d replay samples.\n", n);
fprintf("Variables exported to the base workspace.\n");
fprintf("Normalized sample time: 1 sample (not seconds).\n");
fprintf("Saved replay data to %s\n", replayFile);
end
