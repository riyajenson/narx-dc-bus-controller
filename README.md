# LSTM DC-Bus PI Controller Replacement

This project replaces a conventional PI controller for DC-bus voltage
regulation with an AI controller. The final accepted model is a stateful LSTM
neural network implemented and benchmarked in MATLAB/Simulink.

The final solution uses an LSTM trained on generated DC-bus control episodes
so the controller learns dynamic behavior from sequential data.

## Objective

Train a neural controller that can sit in the PI controller's position and
produce the controller command from:

```text
reference voltage, sensed DC-bus voltage, voltage error -> control command
```

## Final Result

The final Simulink benchmark compares the PI expert and LSTM controller on the
same synthetic DC-bus reference/load scenario.

```text
PI voltage RMSE:    0.800456 V
LSTM voltage RMSE:  0.795095 V
LSTM RMSE change:  -0.670 %
PI peak error:      5.1515 V
LSTM peak error:    4.7742 V
```

The LSTM slightly improves RMSE and peak error in the final Simulink scenario.
Across randomized unseen closed-loop scenarios, it remains stable and produces
smoother control action, while not consistently outperforming PI on every
tracking metric.

See [docs/RESULTS.md](docs/RESULTS.md) for the full result summary and
limitations.

## Important Scope Note

The original converter Simulink plant was not provided with the data. Because
of that, the working proof-of-concept uses a disclosed simplified first-order
synthetic DC-bus plant. A PI expert generates training trajectories, and the
trained LSTM is tested against the same PI expert under identical scenarios.

This demonstrates an AI/ML PI-controller replacement workflow. It does not
claim hardware validation or validation on the original unavailable converter
plant.

## Repository Layout

```text
data/
  raw/          Original supplied dataset
  processed/    Generated MATLAB datasets, ignored by git
docs/           Methodology, experiments, results, and limitations
matlab/         MATLAB scripts and Simulink MATLAB System blocks
models/         Trained networks, ignored by git
results/        Selected committed plots/metrics plus ignored generated files
simulink/
  final/        Final PI-versus-LSTM Simulink benchmark
```

## Quick Start

Open MATLAB in the repository root and run:

```matlab
addpath("matlab");
generate_synthetic_training_data;
train_synthetic_lstm_controller;
evaluate_synthetic_lstm_controller;
compare_closed_loop_controllers;
build_final_simulink_benchmark;
finalOut = sim("dc_bus_pi_vs_lstm");
summarize_final_simulink_run(finalOut);
```

Useful result files:

```text
results/final_simulink_metrics.txt
results/final_simulink_voltage.png
results/synthetic_lstm_metrics.txt
results/synthetic_lstm_prediction_trace.png
results/synthetic_lstm_regression.png
results/closed_loop_comparison.txt
results/closed_loop_comparison.png
```

## Model

- Controller type: stateful LSTM neural network
- Inputs: reference voltage, sensed voltage, voltage error
- Output: controller command
- Training data: 180 randomized synthetic DC-bus episodes
- Test data: unseen synthetic episodes and a final Simulink benchmark scenario
- Deployment: MATLAB System block inside Simulink

## Explored Alternatives

Additional diagnostic experiments were used during development, including a
fixed-window feedforward controller, an original-data LSTM, and an ARX plant
surrogate. These experiments showed that the original logged data alone was not
enough for a deployable closed-loop controller, which is why the final approach
uses synthetic closed-loop data generation.
