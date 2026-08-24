function compare_closed_loop_controllers()
%COMPARE_CLOSED_LOOP_CONTROLLERS Compare PI and LSTM on unseen plant runs.

cfg = project_config();
modelFile = fullfile(cfg.rootDir, "models", ...
    "synthetic_lstm_controller.mat");
assert(isfile(modelFile), "Run train_synthetic_lstm_controller first.");
trained = load(modelFile, "syntheticLstmNet", "normalization", ...
    "modelMetadata");

rng(20260824, "twister"); % Separate deterministic evaluation seed.
episodeCount = 20;
episodeLength = trained.modelMetadata.episodeLength;
dt = trained.modelMetadata.dt;
nominalVoltage = trained.modelMetadata.nominalVoltage;
limits = trained.modelMetadata.outputLimits;
kp = trained.modelMetadata.expertKp;
ki = trained.modelMetadata.expertKi;
warmup = trained.modelMetadata.warmupSamples;

piSquaredError = [];
lstmSquaredError = [];
piAbsoluteError = [];
lstmAbsoluteError = [];
piPeakErrors = zeros(episodeCount, 1);
lstmPeakErrors = zeros(episodeCount, 1);
piControlVariation = [];
lstmControlVariation = [];
representative = struct();

for episode = 1:episodeCount
    scenario = createScenario(episodeLength, nominalVoltage);
    piResult = simulatePi(scenario, dt, nominalVoltage, limits, kp, ki);
    lstmResult = simulateLstm(scenario, dt, nominalVoltage, limits, trained);

    scored = warmup+1:episodeLength;
    piError = scenario.reference(scored) - piResult.voltage(scored);
    lstmError = scenario.reference(scored) - lstmResult.voltage(scored);
    piSquaredError = [piSquaredError; piError(:).^2]; %#ok<AGROW>
    lstmSquaredError = [lstmSquaredError; lstmError(:).^2]; %#ok<AGROW>
    piAbsoluteError = [piAbsoluteError; abs(piError(:))]; %#ok<AGROW>
    lstmAbsoluteError = [lstmAbsoluteError; abs(lstmError(:))]; %#ok<AGROW>
    piPeakErrors(episode) = max(abs(piError));
    lstmPeakErrors(episode) = max(abs(lstmError));
    piControlVariation = [piControlVariation; ...
        abs(diff(piResult.control(scored))).']; %#ok<AGROW>
    lstmControlVariation = [lstmControlVariation; ...
        abs(diff(lstmResult.control(scored))).']; %#ok<AGROW>

    if episode == 1
        representative.scenario = scenario;
        representative.pi = piResult;
        representative.lstm = lstmResult;
    end
end

metrics.piRmse = sqrt(mean(piSquaredError));
metrics.lstmRmse = sqrt(mean(lstmSquaredError));
metrics.piMae = mean(piAbsoluteError);
metrics.lstmMae = mean(lstmAbsoluteError);
metrics.piMeanPeakError = mean(piPeakErrors);
metrics.lstmMeanPeakError = mean(lstmPeakErrors);
metrics.piMeanControlVariation = mean(piControlVariation);
metrics.lstmMeanControlVariation = mean(lstmControlVariation);
metrics.rmseChangePercent = 100 * ...
    (metrics.lstmRmse - metrics.piRmse) / metrics.piRmse;

if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end
metricsFile = fullfile(cfg.resultsDir, "closed_loop_comparison.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "Unseen closed-loop episodes: %d\n", episodeCount);
fprintf(fid, "Samples per episode: %d\n", episodeLength);
fprintf(fid, "Physical sample time: %.5f s\n", dt);
fprintf(fid, "Warm-up excluded: %d samples\n\n", warmup);
fprintf(fid, "PI voltage RMSE: %.8f V\n", metrics.piRmse);
fprintf(fid, "LSTM voltage RMSE: %.8f V\n", metrics.lstmRmse);
fprintf(fid, "PI voltage MAE: %.8f V\n", metrics.piMae);
fprintf(fid, "LSTM voltage MAE: %.8f V\n", metrics.lstmMae);
fprintf(fid, "PI mean peak error: %.8f V\n", metrics.piMeanPeakError);
fprintf(fid, "LSTM mean peak error: %.8f V\n", metrics.lstmMeanPeakError);
fprintf(fid, "PI mean |delta u|: %.8f\n", metrics.piMeanControlVariation);
fprintf(fid, "LSTM mean |delta u|: %.8f\n", metrics.lstmMeanControlVariation);
fprintf(fid, "LSTM RMSE change versus PI: %.3f %%\n", metrics.rmseChangePercent);
fprintf(fid, "Plant disclosure: simplified synthetic first-order DC-bus model.\n");

time = (0:episodeLength-1) * dt;
fig = figure("Visible", "off");
tiledlayout(2, 1);
nexttile;
plot(time, representative.scenario.reference, "k:", "LineWidth", 1.4);
hold on;
plot(time, representative.pi.voltage, "LineWidth", 1.1);
plot(time, representative.lstm.voltage, "--", "LineWidth", 1.1);
grid on;
ylabel("DC-bus voltage (V)");
legend("Reference", "PI", "LSTM", "Location", "best");
title("Closed-loop comparison on an unseen synthetic scenario");
nexttile;
plot(time, representative.pi.control, "LineWidth", 1.1);
hold on;
plot(time, representative.lstm.control, "--", "LineWidth", 1.1);
grid on;
xlabel("Time (s)");
ylabel("Controller command");
legend("PI", "LSTM", "Location", "best");
exportgraphics(fig, fullfile(cfg.resultsDir, ...
    "closed_loop_comparison.png"));
close(fig);

save(fullfile(cfg.resultsDir, "closed_loop_comparison.mat"), ...
    "metrics", "representative");
fprintf("PI voltage RMSE: %.6f V\n", metrics.piRmse);
fprintf("LSTM voltage RMSE: %.6f V\n", metrics.lstmRmse);
fprintf("LSTM change versus PI: %.3f %%\n", metrics.rmseChangePercent);
end

function scenario = createScenario(n, nominalVoltage)
scenario.tau = 0.20 + 0.35 * rand();
scenario.controlGain = 1.8 + 1.4 * rand();
scenario.initialVoltage = nominalVoltage + (-4 + 8 * rand());
scenario.reference = nominalVoltage * ones(1, n);
scenario.loadDrop = zeros(1, n);
scenario.noise = 0.08 * randn(1, n);

referenceTime = randi([150, 350]);
scenario.reference(referenceTime:end) = nominalVoltage + (-6 + 12 * rand());
loadTime = randi([80, 450]);
scenario.loadDrop(loadTime:end) = -7 + 14 * rand();
secondLoadTime = min(n, loadTime + randi([80, 180]));
if secondLoadTime < n
    scenario.loadDrop(secondLoadTime:end) = ...
        scenario.loadDrop(loadTime) + (-4 + 8 * rand());
end
end

function result = simulatePi(scenario, dt, nominalVoltage, limits, kp, ki)
n = numel(scenario.reference);
result.voltage = zeros(1, n);
result.control = zeros(1, n);
result.voltage(1) = scenario.initialVoltage;
integralState = 0;
for k = 1:n
    measured = result.voltage(k) + scenario.noise(k);
    errorSignal = scenario.reference(k) - measured;
    candidateIntegral = integralState + dt * errorSignal;
    unsaturated = kp * errorSignal + ki * candidateIntegral;
    result.control(k) = min(max(unsaturated, limits(1)), limits(2));
    if result.control(k) == unsaturated || ...
            (result.control(k) == limits(2) && errorSignal < 0) || ...
            (result.control(k) == limits(1) && errorSignal > 0)
        integralState = candidateIntegral;
    end
    if k < n
        result.voltage(k+1) = plantStep(result.voltage(k), ...
            result.control(k), scenario.loadDrop(k), scenario, ...
            dt, nominalVoltage);
    end
end
end

function result = simulateLstm(scenario, dt, nominalVoltage, limits, trained)
n = numel(scenario.reference);
result.voltage = zeros(1, n);
result.control = zeros(1, n);
result.voltage(1) = scenario.initialVoltage;
statefulNet = resetState(trained.syntheticLstmNet);
for k = 1:n
    measured = result.voltage(k) + scenario.noise(k);
    errorSignal = scenario.reference(k) - measured;
    rawInput = [scenario.reference(k); measured; errorSignal];
    normalizedInput = (rawInput - trained.normalization.inputMean) ./ ...
        trained.normalization.inputStd;
    [statefulNet, normalizedOutput] = predictAndUpdateState( ...
        statefulNet, normalizedInput, "ExecutionEnvironment", "cpu");
    command = normalizedOutput * trained.normalization.targetStd + ...
        trained.normalization.targetMean;
    result.control(k) = min(max(double(command), limits(1)), limits(2));
    if k < n
        result.voltage(k+1) = plantStep(result.voltage(k), ...
            result.control(k), scenario.loadDrop(k), scenario, ...
            dt, nominalVoltage);
    end
end
end

function nextVoltage = plantStep(voltage, control, loadDrop, scenario, ...
        dt, nominalVoltage)
derivative = ((nominalVoltage - voltage) + ...
    scenario.controlGain * control - loadDrop) / scenario.tau;
nextVoltage = voltage + dt * derivative;
end
