function evaluate_lstm_controller()
%EVALUATE_LSTM_CONTROLLER Evaluate unseen chronological sequences.

cfg = project_config();
modelFile = fullfile(cfg.rootDir, "models", "lstm_controller.mat");
assert(isfile(modelFile), "Run train_lstm_controller first.");
trained = load(modelFile, "lstmNet", "normalization", "metadata", ...
    "XTest", "YTest");

YPredicted = predict(trained.lstmNet, trained.XTest, "MiniBatchSize", 1);
if ~iscell(YPredicted)
    YPredicted = {YPredicted};
end

actualParts = cell(numel(trained.YTest), 1);
predictedParts = cell(numel(YPredicted), 1);
warmup = trained.metadata.warmupSamples;
for k = 1:numel(trained.YTest)
    actualNormalized = trained.YTest{k};
    predictedNormalized = YPredicted{k};
    firstScored = min(warmup + 1, size(actualNormalized, 2));
    actualParts{k} = actualNormalized(:, firstScored:end) .* ...
        trained.normalization.targetStd + trained.normalization.targetMean;
    predictedParts{k} = predictedNormalized(:, firstScored:end) .* ...
        trained.normalization.targetStd + trained.normalization.targetMean;
end

actual = cat(2, actualParts{:}).';
predicted = cat(2, predictedParts{:}).';
residual = predicted - actual;
rmse = sqrt(mean(residual.^2));
mae = mean(abs(residual));
r2 = 1 - sum(residual.^2) / sum((actual - mean(actual)).^2);

if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end
metricsFile = fullfile(cfg.resultsDir, "lstm_metrics.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "Scored test samples: %d\n", numel(actual));
fprintf(fid, "Warm-up excluded per sequence: %d samples\n", warmup);
fprintf(fid, "RMSE: %.8f\nMAE: %.8f\nR-squared: %.8f\n", rmse, mae, r2);
fprintf(fid, "Predicted-output feedback: false\n");

results = table((1:numel(actual)).', actual, predicted, residual, ...
    VariableNames=["TestSample", "ActualPIOutput", ...
    "PredictedLSTMOutput", "Residual"]);
writetable(results, fullfile(cfg.resultsDir, "lstm_test_predictions.csv"));

fig = figure("Visible", "off");
plot(actual, "LineWidth", 1.1);
hold on;
plot(predicted, "--", "LineWidth", 1.0);
grid on;
xlabel("Chronological scored test sample");
ylabel("Controller output");
title("PI target versus stateful LSTM prediction");
legend("Recorded PI", "LSTM controller", "Location", "best");
exportgraphics(fig, fullfile(cfg.resultsDir, "lstm_prediction_trace.png"));
close(fig);

fig = figure("Visible", "off");
scatter(actual, predicted, 8, "filled");
hold on;
limits = [min([actual; predicted]), max([actual; predicted])];
plot(limits, limits, "k--", "LineWidth", 1.2);
grid on;
axis equal;
xlim(limits);
ylim(limits);
xlabel("Recorded PI output");
ylabel("LSTM output");
title(sprintf("Stateful LSTM test regression, R^2 = %.4f", r2));
exportgraphics(fig, fullfile(cfg.resultsDir, "lstm_regression.png"));
close(fig);

fprintf("LSTM test RMSE: %.8f | MAE: %.8f | R^2: %.6f\n", rmse, mae, r2);
end
