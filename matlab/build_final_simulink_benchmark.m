function build_final_simulink_benchmark()
%BUILD_FINAL_SIMULINK_BENCHMARK Generate the PI-versus-LSTM demonstration.

cfg = project_config();
addpath(fullfile(cfg.rootDir, "matlab"));
assert(isfile(fullfile(cfg.rootDir, "models", ...
    "synthetic_lstm_controller.mat")), "Train the synthetic LSTM first.");

modelName = "dc_bus_pi_vs_lstm";
modelDir = fullfile(cfg.rootDir, "simulink", "final");
modelFile = fullfile(modelDir, modelName + ".slx");
if ~isfolder(modelDir)
    mkdir(modelDir);
end
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if isfile(modelFile)
    error("Final model already exists. Move it before rebuilding: %s", modelFile);
end

dt = 0.01;
time = (0:dt:6).';
referenceValues = 300 * ones(size(time));
referenceValues(time >= 3.3) = 305;
loadValues = zeros(size(time));
loadValues(time >= 2.3) = 5;
loadValues(time >= 3.6) = 2;

referenceScenario.time = time;
referenceScenario.signals.values = referenceValues;
referenceScenario.signals.dimensions = 1;
loadScenario.time = time;
loadScenario.signals.values = loadValues;
loadScenario.signals.dimensions = 1;
assignin("base", "referenceScenario", referenceScenario);
assignin("base", "loadScenario", loadScenario);

new_system(modelName);
open_system(modelName);
add_block("simulink/Sources/From Workspace", modelName + "/Reference", ...
    "VariableName", "referenceScenario", "Position", [40 80 155 110]);
add_block("simulink/Sources/From Workspace", modelName + "/Load disturbance", ...
    "VariableName", "loadScenario", "Position", [40 300 155 330]);
add_block("simulink/User-Defined Functions/MATLAB System", ...
    modelName + "/PI Expert", "System", "PiExpertSystem", ...
    "SimulateUsing", "Interpreted execution", ...
    "Position", [245 55 365 125]);
add_block("simulink/User-Defined Functions/MATLAB System", ...
    modelName + "/LSTM Controller", "System", "LstmControllerSystem", ...
    "SimulateUsing", "Interpreted execution", ...
    "Position", [245 185 365 255]);
add_block("simulink/Discrete/Unit Delay", modelName + "/PI command delay", ...
    "SampleTime", string(dt), "Position", [415 75 450 105]);
add_block("simulink/Discrete/Unit Delay", modelName + "/LSTM command delay", ...
    "SampleTime", string(dt), "Position", [415 205 450 235]);
add_block("simulink/User-Defined Functions/MATLAB System", ...
    modelName + "/PI Plant", "System", "SyntheticDcBusPlantSystem", ...
    "SimulateUsing", "Interpreted execution", ...
    "Position", [510 55 635 125]);
add_block("simulink/User-Defined Functions/MATLAB System", ...
    modelName + "/LSTM Plant", "System", "SyntheticDcBusPlantSystem", ...
    "SimulateUsing", "Interpreted execution", ...
    "Position", [510 185 635 255]);
add_block("simulink/Signal Routing/Mux", modelName + "/Voltage comparison", ...
    "Inputs", "3", "Position", [720 75 725 225]);
add_block("simulink/Sinks/Scope", modelName + "/Voltage Scope", ...
    "Position", [780 125 830 175]);
add_block("simulink/Sinks/To Workspace", modelName + "/Save PI voltage", ...
    "VariableName", "finalPiVoltage", "SaveFormat", "Timeseries", ...
    "Position", [710 260 830 290]);
add_block("simulink/Sinks/To Workspace", modelName + "/Save LSTM voltage", ...
    "VariableName", "finalLstmVoltage", "SaveFormat", "Timeseries", ...
    "Position", [710 310 830 340]);

add_line(modelName, "Reference/1", "PI Expert/1", "autorouting", "on");
add_line(modelName, "Reference/1", "LSTM Controller/1", "autorouting", "on");
add_line(modelName, "PI Expert/1", "PI command delay/1", "autorouting", "on");
add_line(modelName, "LSTM Controller/1", "LSTM command delay/1", "autorouting", "on");
add_line(modelName, "PI command delay/1", "PI Plant/1", "autorouting", "on");
add_line(modelName, "LSTM command delay/1", "LSTM Plant/1", "autorouting", "on");
add_line(modelName, "Load disturbance/1", "PI Plant/2", "autorouting", "on");
add_line(modelName, "Load disturbance/1", "LSTM Plant/2", "autorouting", "on");
add_line(modelName, "PI Plant/1", "PI Expert/2", "autorouting", "on");
add_line(modelName, "LSTM Plant/1", "LSTM Controller/2", "autorouting", "on");
add_line(modelName, "Reference/1", "Voltage comparison/1", "autorouting", "on");
add_line(modelName, "PI Plant/1", "Voltage comparison/2", "autorouting", "on");
add_line(modelName, "LSTM Plant/1", "Voltage comparison/3", "autorouting", "on");
add_line(modelName, "Voltage comparison/1", "Voltage Scope/1", "autorouting", "on");
add_line(modelName, "PI Plant/1", "Save PI voltage/1", "autorouting", "on");
add_line(modelName, "LSTM Plant/1", "Save LSTM voltage/1", "autorouting", "on");

set_param(modelName, "SolverType", "Fixed-step", ...
    "Solver", "FixedStepDiscrete", "FixedStep", string(dt), ...
    "StartTime", "0", "StopTime", "6", "ReturnWorkspaceOutputs", "on");
save_system(modelName, modelFile);
open_system(modelName);
fprintf("Saved final Simulink benchmark to %s\n", modelFile);
fprintf("Run with: finalOut = sim('%s');\n", modelName);
end
