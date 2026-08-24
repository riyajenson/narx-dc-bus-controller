function evaluate_synthetic_lstm_controller()
%EVALUATE_SYNTHETIC_LSTM_CONTROLLER Evaluate unseen randomized episodes.

cfg = project_config();
modelFile = fullfile(cfg.rootDir, "models", ...
    "synthetic_lstm_controller.mat");
assert(isfile(modelFile), "Run train_synthetic_lstm_controller first.");
trained = load(modelFile);

YPredicted = predict(trained.syntheticLstmNet, trained.XTest, ...
    "MiniBatchSize", 1);
if ~iscell(YPredicted)
    YPredicted = {YPredicted};
end

warmup = trained.modelMetadata.warmupSamples;
actualParts = cell(numel(trained.YTest), 1);
predictedParts = cell(numel(YPredicted), 1);
for k = 1:numel(trained.YTest)
    actualNormalized = trained.YTest{k};
    predictedNormalized = YPredicted{k};
    actualParts{k} = actualNormalized(:, warmup+1:end) .* ...
        trained.normalization.targetStd + trained.normalization.targetMean;
    predictedParts{k} = predictedNormalized(:, warmup+1:end) .* ...
        trained.normalization.targetStd + trained.normalization.targetMean;
end

actual = cat(2, actualParts{:}).';
predicted = cat(2, predictedParts{:}).';
predicted = min(max(predicted, trained.modelMetadata.outputLimits(1)), ...
    trained.modelMetadata.outputLimits(2));
residual = predicted - actual;
rmse = sqrt(mean(residual.^2));
mae = mean(abs(residual));
r2 = 1 - sum(residual.^2) / sum((actual - mean(actual)).^2);

if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end
metricsFile = fullfile(cfg.resultsDir, "synthetic_lstm_metrics.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "Unseen test episodes: %d\n", numel(trained.XTest));
fprintf(fid, "Scored samples: %d\n", numel(actual));
fprintf(fid, "Warm-up per episode: %d samples\n", warmup);
fprintf(fid, "RMSE: %.8f\nMAE: %.8f\nR-squared: %.8f\n", rmse, mae, r2);
fprintf(fid, "Predicted-output feedback: false\n");

fig = figure("Visible", "off");
plot(actual, "LineWidth", 1.1);
hold on;
plot(predicted, "--", "LineWidth", 1.0);
grid on;
xlabel("Scored sample across unseen episodes");
ylabel("Controller command");
title("Synthetic PI expert versus LSTM controller");
legend("Expert PI", "LSTM", "Location", "best");
exportgraphics(fig, fullfile(cfg.resultsDir, ...
    "synthetic_lstm_prediction_trace.png"));
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
xlabel("Expert PI command");
ylabel("LSTM command");
title(sprintf("Synthetic unseen-episode regression, R^2 = %.4f", r2));
exportgraphics(fig, fullfile(cfg.resultsDir, ...
    "synthetic_lstm_regression.png"));
close(fig);

fprintf("Synthetic LSTM RMSE: %.8f | MAE: %.8f | R^2: %.6f\n", ...
    rmse, mae, r2);
end
