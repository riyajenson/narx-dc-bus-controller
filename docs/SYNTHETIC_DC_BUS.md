# Synthetic DC-bus training environment

## Purpose

The supplied spreadsheet does not contain enough controller state or operating
variables for a deployable PI replacement. No original Simulink plant was
provided. The final proof of concept therefore uses a disclosed, simplified
first-order DC-bus model to generate complete and diverse expert demonstrations.

## Plant

```text
dV/dt = ((Vnom - V) + controlGain*u - loadDrop) / tau
```

Each episode randomizes the time constant, control gain, initial voltage,
reference step, load step, second disturbance, and measurement noise. A PI
expert with output saturation and conditional-integration anti-windup produces
the demonstration command.

This is an educational control benchmark, not a switching-converter or
hardware-validated plant.

## Final controller

A 64-unit stateful LSTM receives reference voltage, sensed voltage, and voltage
error. It predicts the controller command without using its previous predicted
output as an input.

## Run

```matlab
generate_synthetic_training_data;
train_synthetic_lstm_controller;
evaluate_synthetic_lstm_controller;
type("results\synthetic_lstm_metrics.txt");
compare_closed_loop_controllers;
type("results\closed_loop_comparison.txt");
```

Only the first 70% of randomized episodes train the network. The final 15% are
held out as unseen test episodes.

The final acceptance test runs the PI and LSTM independently in feedback with
identical unseen plant parameters, reference steps, load disturbances, initial
conditions, and measurement noise. Controller-command imitation alone is not
treated as proof of successful control.
