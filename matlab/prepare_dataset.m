function prepare_dataset()
%PREPARE_DATASET Validate and convert the Excel data to time-series cells.

cfg = project_config();
assert(isfile(cfg.rawDataFile), "Dataset not found: %s", cfg.rawDataFile);

data = readtable(cfg.rawDataFile, "VariableNamingRule", "preserve");
required = ["Vdc reference", "Vdc Sensed", "PI Input", "PI Output"];
assert(all(ismember(required, string(data.Properties.VariableNames))), ...
    "The workbook does not contain the expected columns.");

reference = double(data.("Vdc reference"));
sensed = double(data.("Vdc Sensed"));
piInput = double(data.("PI Input"));
piOutput = double(data.("PI Output"));

valid = isfinite(reference) & isfinite(sensed) & ...
    isfinite(piInput) & isfinite(piOutput);
reference = reference(valid);
sensed = sensed(valid);
piInput = piInput(valid);
piOutput = piOutput(valid);

% Preserve temporal order while reducing five-day prototype training time.
stride = max(1, floor(numel(reference) / cfg.maxSamples));
selected = 1:stride:numel(reference);
reference = reference(selected);
sensed = sensed(selected);
piInput = piInput(selected);
piOutput = piOutput(selected);
errorSignal = reference - sensed;

inputsMatrix = [errorSignal.'; sensed.'];
targetsMatrix = piOutput.';
inputs = con2seq(inputsMatrix);
targets = con2seq(targetsMatrix);

if ~isfolder(fileparts(cfg.preparedDataFile))
    mkdir(fileparts(cfg.preparedDataFile));
end

save(cfg.preparedDataFile, "inputs", "targets", "reference", "sensed", ...
    "errorSignal", "piInput", "piOutput", "stride");

fprintf("Prepared %d chronological samples (stride %d).\n", ...
    numel(reference), stride);
fprintf("Reference range: %.3f to %.3f V\n", min(reference), max(reference));
fprintf("Sensed range: %.3f to %.3f V\n", min(sensed), max(sensed));
fprintf("PI output range: %.5f to %.5f\n", min(piOutput), max(piOutput));
end
