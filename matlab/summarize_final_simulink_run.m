function summarize_final_simulink_run(finalOut)
%SUMMARIZE_FINAL_SIMULINK_RUN Save metrics from dc_bus_pi_vs_lstm.slx.

cfg = project_config();
if ~isfolder(cfg.resultsDir)
    mkdir(cfg.resultsDir);
end

piSeries = finalOut.get("finalPiVoltage");
lstmSeries = finalOut.get("finalLstmVoltage");
referenceScenario = evalin("base", "referenceScenario");

time = piSeries.Time(:);
piVoltage = squeeze(piSeries.Data);
lstmVoltage = squeeze(lstmSeries.Data);
reference = interp1(referenceScenario.time(:), ...
    referenceScenario.signals.values(:), time, "previous", "extrap");

valid = isfinite(reference) & isfinite(piVoltage) & isfinite(lstmVoltage);
time = time(valid);
reference = reference(valid);
piVoltage = piVoltage(valid);
lstmVoltage = lstmVoltage(valid);

piError = reference - piVoltage;
lstmError = reference - lstmVoltage;

metrics.piRmse = sqrt(mean(piError.^2));
metrics.lstmRmse = sqrt(mean(lstmError.^2));
metrics.piMae = mean(abs(piError));
metrics.lstmMae = mean(abs(lstmError));
metrics.piPeakError = max(abs(piError));
metrics.lstmPeakError = max(abs(lstmError));
metrics.rmseChangePercent = 100 * ...
    (metrics.lstmRmse - metrics.piRmse) / metrics.piRmse;

metricsFile = fullfile(cfg.resultsDir, "final_simulink_metrics.txt");
fid = fopen(metricsFile, "w");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "Model: dc_bus_pi_vs_lstm.slx\n");
fprintf(fid, "Samples: %d\n", numel(time));
fprintf(fid, "PI voltage RMSE: %.8f V\n", metrics.piRmse);
fprintf(fid, "LSTM voltage RMSE: %.8f V\n", metrics.lstmRmse);
fprintf(fid, "PI voltage MAE: %.8f V\n", metrics.piMae);
fprintf(fid, "LSTM voltage MAE: %.8f V\n", metrics.lstmMae);
fprintf(fid, "PI peak error: %.8f V\n", metrics.piPeakError);
fprintf(fid, "LSTM peak error: %.8f V\n", metrics.lstmPeakError);
fprintf(fid, "LSTM RMSE change versus PI: %.3f %%\n", ...
    metrics.rmseChangePercent);
fprintf(fid, "Plant disclosure: simplified synthetic first-order DC-bus model.\n");

fig = figure("Visible", "off");
plot(time, reference, "k:", "LineWidth", 1.4);
hold on;
plot(time, piVoltage, "LineWidth", 1.1);
plot(time, lstmVoltage, "--", "LineWidth", 1.1);
grid on;
xlabel("Time (s)");
ylabel("DC-bus voltage (V)");
legend("Reference", "PI", "LSTM", "Location", "best");
title("Final Simulink PI-versus-LSTM benchmark");
exportgraphics(fig, fullfile(cfg.resultsDir, "final_simulink_voltage.png"));
close(fig);

save(fullfile(cfg.resultsDir, "final_simulink_metrics.mat"), "metrics");
fprintf("Final Simulink PI RMSE: %.6f V\n", metrics.piRmse);
fprintf("Final Simulink LSTM RMSE: %.6f V\n", metrics.lstmRmse);
fprintf("LSTM change versus PI: %.3f %%\n", metrics.rmseChangePercent);
end
