function evaluate_narx_controller()
%EVALUATE_NARX_CONTROLLER Evaluate imitation quality on chronological test data.

cfg = project_config();
assert(isfile(cfg.modelFile), "Run train_narx_controller first.");
load(cfg.preparedDataFile, "inputs", "targets");
load(cfg.modelFile, "netOpen", "trainingRecord");

[x, xi, ai, t] = preparets(netOpen, inputs, {}, targets);
y = netOpen(x, xi, ai);
targetVector = cell2mat(t);
predictionVector = cell2mat(y);

testIndices = trainingRecord.testInd;
assert(~isempty(testIndices), "No test indices were created.");
actual = targetVector(testIndices).';
predicted = predictionVector(testIndices).';
residual = predicted - actual;

rmse = sqrt(mean(residual.^2));
mae = mean(abs(residual));
r2 = 1 - sum(residual.^2) / sum((actual - mean(actual)).^2);

if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end

results = table(testIndices(:), actual, predicted, residual, ...
    "VariableNames", ["SequenceIndex", "ActualPIOutput", ...
    "PredictedNARXOutput", "Residual"]);
writetable(results, fullfile(cfg.resultsDir, "test_predictions.csv"));

metricsFile = fullfile(cfg.resultsDir, "metrics.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "Test samples: %d\nRMSE: %.8f\nMAE: %.8f\nR-squared: %.8f\n", ...
    numel(actual), rmse, mae, r2);

traceFigure = figure("Visible", "off");
plot(actual, "LineWidth", 1.1);
hold on;
plot(predicted, "--", "LineWidth", 1.0);
grid on;
xlabel("Chronological test sample");
ylabel("Controller output");
title("PI target versus NARX prediction");
legend("Recorded PI", "NARX", "Location", "best");
exportgraphics(traceFigure, fullfile(cfg.resultsDir, "prediction_trace.png"));
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
ylabel("Predicted NARX output");
title(sprintf("Test regression, R^2 = %.4f", r2));
exportgraphics(regressionFigure, fullfile(cfg.resultsDir, "regression.png"));
close(regressionFigure);

fprintf("Test RMSE: %.8f | MAE: %.8f | R^2: %.6f\n", rmse, mae, r2);
end
