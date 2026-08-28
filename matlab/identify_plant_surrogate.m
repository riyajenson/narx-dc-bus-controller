function identify_plant_surrogate()
%IDENTIFY_PLANT_SURROGATE Fit a small ARX model without extra toolboxes.
% This is a data-driven simulation surrogate, not a physical DC-bus model.

cfg = project_config();
assert(isfile(cfg.rawDataFile), "Dataset not found: %s", cfg.rawDataFile);

data = readtable(cfg.rawDataFile, "VariableNamingRule", "preserve");
y = double(data.("Vdc Sensed"));
u = double(data.("PI Output"));
valid = isfinite(y) & isfinite(u);
y = y(valid);
u = u(valid);

% Keep temporal order and use a manageable data scale.
stride = max(1, floor(numel(y) / cfg.maxSamples));
y = y(1:stride:end);
u = u(1:stride:end);

candidateOrders = 1:4;
candidateDelays = 1:4;
ridgeLambda = 1e-6;
bestValidationRmse = inf;
best = struct();

for na = candidateOrders
    for nb = candidateOrders
        for nk = candidateDelays
            [X, target, sampleIndex] = buildRegression(y, u, na, nb, nk);
            n = size(X, 1);
            trainEnd = floor(0.70 * n);
            validationEnd = floor(0.85 * n);

            penalty = eye(size(X, 2));
            penalty(end, end) = 0; % Do not penalize the intercept.
            theta = (X(1:trainEnd, :)' * X(1:trainEnd, :) + ...
                ridgeLambda * penalty) \ ...
                (X(1:trainEnd, :)' * target(1:trainEnd));

            validationPrediction = X(trainEnd+1:validationEnd, :) * theta;
            validationTarget = target(trainEnd+1:validationEnd);
            validationRmse = sqrt(mean((validationPrediction - validationTarget).^2));

            if validationRmse < bestValidationRmse
                bestValidationRmse = validationRmse;
                best.na = na;
                best.nb = nb;
                best.nk = nk;
                best.theta = theta;
                best.sampleIndex = sampleIndex;
                best.trainEnd = trainEnd;
                best.validationEnd = validationEnd;
            end
        end
    end
end

[X, target, sampleIndex] = buildRegression(y, u, best.na, best.nb, best.nk);
testRows = best.validationEnd+1:size(X, 1);
oneStepPrediction = X(testRows, :) * best.theta;
testTarget = target(testRows);
oneStepResidual = oneStepPrediction - testTarget;
oneStepRmse = sqrt(mean(oneStepResidual.^2));
oneStepMae = mean(abs(oneStepResidual));
oneStepR2 = calculateR2(testTarget, oneStepPrediction);

firstTestSample = sampleIndex(testRows(1));
freeRunY = y;
for k = firstTestSample:numel(y)
    row = regressionRow(freeRunY, u, k, best.na, best.nb, best.nk);
    freeRunY(k) = row * best.theta;
end
freeRunTarget = y(firstTestSample:end);
freeRunPrediction = freeRunY(firstTestSample:end);
freeRunResidual = freeRunPrediction - freeRunTarget;
freeRunRmse = sqrt(mean(freeRunResidual.^2));
freeRunMae = mean(abs(freeRunResidual));
freeRunR2 = calculateR2(freeRunTarget, freeRunPrediction);

plant = best;
plant.stride = stride;
plant.ridgeLambda = ridgeLambda;
plant.equation = "y(k)=sum(a_i*y(k-i))+sum(b_j*u(k-nk-j+1))+c";
plant.warning = "Data-driven surrogate; not a physical or stability-certified plant.";

modelFile = fullfile(cfg.rootDir, "models", "dc_bus_arx_surrogate.mat");
save(modelFile, "plant");

if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end
metricsFile = fullfile(cfg.resultsDir, "plant_surrogate_metrics.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "ARX orders: na=%d, nb=%d, nk=%d\n", plant.na, plant.nb, plant.nk);
fprintf(fid, "Validation one-step RMSE: %.8f V\n", bestValidationRmse);
fprintf(fid, "Test one-step RMSE: %.8f V\n", oneStepRmse);
fprintf(fid, "Test one-step MAE: %.8f V\n", oneStepMae);
fprintf(fid, "Test one-step R-squared: %.8f\n", oneStepR2);
fprintf(fid, "Test free-run RMSE: %.8f V\n", freeRunRmse);
fprintf(fid, "Test free-run MAE: %.8f V\n", freeRunMae);
fprintf(fid, "Test free-run R-squared: %.8f\n", freeRunR2);

fig = figure("Visible", "off");
plot(freeRunTarget, "LineWidth", 1.1);
hold on;
plot(freeRunPrediction, "--", "LineWidth", 1.0);
grid on;
xlabel("Chronological test sample");
ylabel("Vdc sensed (V)");
title(sprintf("ARX surrogate free-run test, R^2 = %.4f", freeRunR2));
legend("Recorded Vdc", "ARX surrogate", "Location", "best");
exportgraphics(fig, fullfile(cfg.resultsDir, "plant_surrogate_free_run.png"));
close(fig);

fprintf("Selected ARX(%d,%d,%d).\n", plant.na, plant.nb, plant.nk);
fprintf("One-step test RMSE: %.6f V | R^2: %.6f\n", oneStepRmse, oneStepR2);
fprintf("Free-run test RMSE: %.6f V | R^2: %.6f\n", freeRunRmse, freeRunR2);
fprintf("Saved surrogate to %s\n", modelFile);
end

function [X, target, sampleIndex] = buildRegression(y, u, na, nb, nk)
firstSample = max(na + 1, nk + nb);
sampleIndex = (firstSample:numel(y)).';
X = zeros(numel(sampleIndex), na + nb + 1);
for rowIndex = 1:numel(sampleIndex)
    X(rowIndex, :) = regressionRow(y, u, sampleIndex(rowIndex), na, nb, nk);
end
target = y(sampleIndex);
end

function row = regressionRow(y, u, k, na, nb, nk)
pastY = y(k-(1:na)).';
pastU = u(k-nk-(0:nb-1)).';
row = [pastY, pastU, 1];
end

function r2 = calculateR2(actual, predicted)
denominator = sum((actual - mean(actual)).^2);
if denominator == 0
    r2 = NaN;
else
    r2 = 1 - sum((actual - predicted).^2) / denominator;
end
end
