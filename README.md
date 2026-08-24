# NARX DC-Bus Controller

An AI-based DC-bus voltage-control project that replaces a conventional PI
controller with a nonlinear autoregressive neural network with exogenous inputs
(NARX). The controller is trained from MATLAB/Simulink PI-controller data and
then evaluated against the original PI baseline.

## Objective

Learn the dynamic mapping

```text
current/past voltage error + past controller output -> next control output
```

and use the trained network in the PI controller's location in Simulink.

## Repository layout

```text
data/
  raw/          Original, immutable dataset
  processed/    Generated training data
docs/           Design, MATLAB, and experiment instructions
matlab/         Reproducible MATLAB training and evaluation scripts
models/         Generated trained networks (not committed)
results/        Generated plots and metrics (not committed)
```

## Quick start

1. Open MATLAB in this repository's root directory.
2. Ensure Deep Learning Toolbox and Simulink are installed.
3. Run:

```matlab
addpath("matlab");
prepare_dataset;
train_narx_controller;
evaluate_narx_controller;
identify_plant_surrogate;
prepare_simulink_replay;
```

4. Follow [the Simulink integration guide](docs/MATLAB_SIMULINK_GUIDE.md).

Because the original DC-bus plant was not supplied, see the
[surrogate-plant methodology](docs/SURROGATE_PLANT.md) before making
closed-loop claims.

The ARX surrogate did not pass free-run validation, so the final demonstration
uses the documented [Simulink replay workflow](docs/SIMULINK_REPLAY.md).

The original closed-loop NARX accumulated feedback error during replay, and a
fixed-window explicit-memory MLP could not reconstruct the longer controller
state. The final candidate is therefore a
[stateful LSTM controller](docs/LSTM_CONTROLLER.md) that uses recurrent memory
without predicted-output feedback.

Because the provided data and original plant were insufficient, the working
proof-of-concept is trained on a fully disclosed
[synthetic DC-bus environment](docs/SYNTHETIC_DC_BUS.md) with randomized plant
parameters and disturbances.

## Final result

On 20 unseen closed-loop synthetic scenarios, the LSTM maintained stable DC-bus
regulation with `0.8491 V` RMSE versus `0.7547 V` for the PI expert. It matched
peak error closely and reduced mean controller-command variation by about 58%.
See [the complete results and limitations](docs/RESULTS.md).

Generate the final Simulink benchmark with:

```matlab
build_final_simulink_benchmark;
```

## Model

- Inputs: DC-bus voltage error and sensed DC-bus voltage
- Input delays: 1 and 2 samples
- Feedback delays: 1 and 2 samples
- Hidden layers: 16 and 8 neurons
- Training algorithm: Bayesian regularization
- Baseline target: recorded PI-controller output
- Safety: output saturation to the recorded PI range

## Evaluation

Report RMSE, MAE, R-squared, voltage overshoot, settling time, steady-state
error, and controller-output smoothness. Split time-series data chronologically
to avoid future-data leakage.

## Status

Initial five-day prototype scaffold. Generated datasets, trained models, and
result plots are intentionally excluded from version control.
