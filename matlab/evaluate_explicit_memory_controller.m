function evaluate_explicit_memory_controller()
%EVALUATE_EXPLICIT_MEMORY_CONTROLLER Test without autoregressive feedback.

cfg = project_config();
modelFile = fullfile(cfg.rootDir, "models", ...
    "explicit_memory_controller.mat");
assert(isfile(modelFile), "Run train_explicit_memory_controller first.");

data = load(cfg.preparedDataFile, "piInput", "sensed", "piOutput");
trained = load(modelFile, "net", "trainingRecord");
[features, targets] = build_explicit_memory_features( ...
    data.piInput, data.sensed, data.piOutput);

predictions = trained.net(features);
testIndices = trained.trainingRecord.testInd;
actual = targets(testIndices).';
predicted = predictions(testIndices).';
residual = predicted - actual;

rmse = sqrt(mean(residual.^2));
mae = mean(abs(residual));
r2 = 1 - sum(residual.^2) / sum((actual - mean(actual)).^2);

if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end

metricsFile = fullfile(cfg.resultsDir, ...
    "explicit_memory_metrics.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "Test samples: %d\n", numel(actual));
fprintf(fid, "RMSE: %.8f\nMAE: %.8f\nR-squared: %.8f\n", rmse, mae, r2);
fprintf(fid, "Autoregressive output feedback: false\n");

results = table(testIndices(:), actual, predicted, residual, ...
    VariableNames=["SequenceIndex", "ActualPIOutput", ...
    "PredictedNeuralOutput", "Residual"]);
writetable(results, fullfile(cfg.resultsDir, ...
    "explicit_memory_test_predictions.csv"));

traceFigure = figure("Visible", "off");
plot(actual, "LineWidth", 1.1);
hold on;
plot(predicted, "--", "LineWidth", 1.0);
grid on;
xlabel("Chronological test sample");
ylabel("Controller output");
title("PI target versus explicit-memory neural prediction");
legend("Recorded PI", "Neural controller", "Location", "best");
exportgraphics(traceFigure, fullfile(cfg.resultsDir, ...
    "explicit_memory_prediction_trace.png"));
close(traceFigure);

regressionFigure = figure("Visible", "off");
scatter(actual, predicted, 8, "filled");
hold on;
limits = [min([actual; predicted]), max([actual; predicted])];
plot(limits, limits, "k--", "LineWidth", 1.2);
grid on;
axis equal;
xlim(limits);
ylim(limits);
xlabel("Recorded PI output");
ylabel("Neural-controller output");
title(sprintf("Explicit-memory test regression, R^2 = %.4f", r2));
exportgraphics(regressionFigure, fullfile(cfg.resultsDir, ...
    "explicit_memory_regression.png"));
close(regressionFigure);

fprintf("Explicit-memory test RMSE: %.8f | MAE: %.8f | R^2: %.6f\n", ...
    rmse, mae, r2);
end
