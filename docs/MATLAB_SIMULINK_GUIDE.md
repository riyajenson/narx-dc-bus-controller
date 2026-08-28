# MATLAB and Simulink guide

## Requirements

- MATLAB
- Deep Learning Toolbox
- Simulink

Note: The original DC-bus Simulink plant was not supplied. The project uses a
disclosed synthetic first-order DC-bus plant for benchmarking.

## 1. Generate synthetic training data

Open MATLAB, browse to the repository root, and run:

```matlab
addpath("matlab");
generate_synthetic_training_data;
```

Expected generated files:

- `data/processed/synthetic_dc_bus_training.mat`

This creates 180 randomized episodes of PI expert demonstrations on a
synthetic first-order DC-bus plant.

## 2. Train the LSTM controller

```matlab
train_synthetic_lstm_controller;
```

Expected generated files:

- `models/synthetic_lstm_controller.mat`

## 3. Evaluate offline

```matlab
evaluate_synthetic_lstm_controller;
```

Expected generated files:

- `results/synthetic_lstm_metrics.txt`
- `results/synthetic_lstm_prediction_trace.png`
- `results/synthetic_lstm_regression.png`

Before using Simulink, check that:

- test RMSE and MAE are acceptably small;
- test R-squared is positive and close to 1;
- predicted output follows the expert PI output without obvious lag.

Low imitation error is necessary, but it does not prove closed-loop stability.

## 4. Closed-loop comparison

```matlab
compare_closed_loop_controllers;
```

Expected generated files:

- `results/closed_loop_comparison.txt`
- `results/closed_loop_comparison.png`

This runs PI and LSTM independently in feedback with identical unseen plant
parameters, reference steps, load disturbances, and measurement noise.

## 5. Build and run the final Simulink benchmark

```matlab
build_final_simulink_benchmark;
finalOut = sim("dc_bus_pi_vs_lstm");
summarize_final_simulink_run(finalOut);
```

Expected generated files:

- `simulink/final/dc_bus_pi_vs_lstm.slx`
- `results/final_simulink_metrics.txt`
- `results/final_simulink_voltage.png`

The model contains two parallel control loops (PI expert and LSTM) each
feeding their own synthetic plant block with identical reference and load
signals.

## 6. Final comparison

For both controllers calculate:

- voltage RMSE;
- peak error;
- voltage MAE;
- control effort and output variation.

The final claim should be that the LSTM replaces the PI controller only if the
closed-loop results remain stable and compare favorably across disturbances.

## Development note

Earlier original-data-only experiments showed that imitation accuracy on logged
PI output does not automatically produce a reliable closed-loop controller.
The final workflow therefore trains the LSTM on generated closed-loop episodes
where the reference, sensed voltage, load disturbance, and PI expert command
are all available.
