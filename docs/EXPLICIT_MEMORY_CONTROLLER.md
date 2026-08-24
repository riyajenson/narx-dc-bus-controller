# Explicit-memory neural controller

## Motivation

The first NARX network achieved strong teacher-forced offline accuracy but
failed Simulink closed-loop replay because prediction errors accumulated through
autoregressive output feedback. The replacement controller uses only measurable
signals and causal error history.

## Inputs

The feedforward neural network receives seven features:

1. Current recorded PI input/error.
2. Error delayed by one sample.
3. Error delayed by two samples.
4. Error change over one sample.
5. Four-sample mean error.
6. Thirty-two-sample mean error.
7. Current sensed DC-bus voltage.

The short and long moving averages provide bounded memory without feeding the
network's own output back into its input.

## Architecture

- Hidden layers: 24 and 12 neurons
- Training: Bayesian regularization
- Output: controller command
- Chronological split: 70% training, 15% validation, 15% testing
- Autoregressive predicted-output feedback: none

## Run

```matlab
train_explicit_memory_controller;
evaluate_explicit_memory_controller;
type("results\explicit_memory_metrics.txt");
```

Only proceed to Simulink replay if the chronological test trace is stable and
the test metrics are acceptable.
