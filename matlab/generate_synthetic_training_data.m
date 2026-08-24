function generate_synthetic_training_data()
%GENERATE_SYNTHETIC_TRAINING_DATA Create diverse PI expert demonstrations.

cfg = project_config();
rng(cfg.randomSeed, "twister");

episodeCount = 180;
episodeLength = 600;
dt = 0.01;
nominalVoltage = 300;
outputLimits = [-10, 10];
expertKp = 0.65;
expertKi = 2.5;

inputs = cell(episodeCount, 1);
targets = cell(episodeCount, 1);
scenarios = repmat(struct(), episodeCount, 1);

for episode = 1:episodeCount
    tau = 0.20 + 0.35 * rand();
    controlGain = 1.8 + 1.4 * rand();
    reference = nominalVoltage * ones(1, episodeLength);
    loadDrop = zeros(1, episodeLength);

    referenceStepTime = randi([150, 350]);
    referenceStep = -6 + 12 * rand();
    reference(referenceStepTime:end) = nominalVoltage + referenceStep;

    loadStepTime = randi([80, 450]);
    loadStep = -7 + 14 * rand();
    loadDrop(loadStepTime:end) = loadStep;

    secondLoadTime = min(episodeLength, loadStepTime + randi([80, 180]));
    if secondLoadTime < episodeLength
        loadDrop(secondLoadTime:end) = loadStep + (-4 + 8 * rand());
    end

    voltage = zeros(1, episodeLength);
    measured = zeros(1, episodeLength);
    control = zeros(1, episodeLength);
    voltage(1) = nominalVoltage + (-4 + 8 * rand());
    integralState = 0;

    for k = 1:episodeLength
        measured(k) = voltage(k) + 0.08 * randn();
        errorSignal = reference(k) - measured(k);
        candidateIntegral = integralState + dt * errorSignal;
        unsaturated = expertKp * errorSignal + expertKi * candidateIntegral;
        control(k) = min(max(unsaturated, outputLimits(1)), outputLimits(2));

        % Conditional integration provides simple expert anti-windup.
        if control(k) == unsaturated || ...
                (control(k) == outputLimits(2) && errorSignal < 0) || ...
                (control(k) == outputLimits(1) && errorSignal > 0)
            integralState = candidateIntegral;
        end

        if k < episodeLength
            derivative = ((nominalVoltage - voltage(k)) + ...
                controlGain * control(k) - loadDrop(k)) / tau;
            voltage(k+1) = voltage(k) + dt * derivative;
        end
    end

    errorSequence = reference - measured;
    inputs{episode} = [reference; measured; errorSequence];
    targets{episode} = control;
    scenarios(episode).tau = tau;
    scenarios(episode).controlGain = controlGain;
    scenarios(episode).referenceStepTime = referenceStepTime;
    scenarios(episode).referenceStep = referenceStep;
    scenarios(episode).loadStepTime = loadStepTime;
    scenarios(episode).loadStep = loadStep;
end

metadata.episodeCount = episodeCount;
metadata.episodeLength = episodeLength;
metadata.dt = dt;
metadata.nominalVoltage = nominalVoltage;
metadata.outputLimits = outputLimits;
metadata.expertKp = expertKp;
metadata.expertKi = expertKi;
metadata.plantEquation = ...
    "dV/dt=((Vnom-V)+controlGain*u-loadDrop)/tau";
metadata.disclosure = ...
    "Synthetic first-order proof-of-concept plant; not the unavailable original converter.";

outputFile = fullfile(cfg.rootDir, "data", "processed", ...
    "synthetic_dc_bus_training.mat");
save(outputFile, "inputs", "targets", "scenarios", "metadata", "-v7.3");
fprintf("Generated %d episodes x %d samples (%d total).\n", ...
    episodeCount, episodeLength, episodeCount * episodeLength);
fprintf("Saved synthetic training data to %s\n", outputFile);
end
