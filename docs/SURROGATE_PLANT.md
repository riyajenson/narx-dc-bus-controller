# Data-driven plant surrogate

## Outcome

The fitted surrogate was rejected for final controller validation. Its test
free-run R-squared was `-0.0341`, so it performed worse than a constant-mean
prediction. The script is retained as a transparent negative experiment, not
as the project's plant model.

## Why it exists

No original DC-bus Simulink plant was supplied. The project therefore fits a
compact autoregressive model with exogenous input (ARX) from the recorded
controller output and sensed DC-bus voltage.

The surrogate supports a reproducible proof-of-concept comparison. It must not
be described as the original physical converter or as evidence of hardware
stability.

## Model

The candidate family is:

```text
Vdc(k) = a1*Vdc(k-1) + ... + b1*u(k-nk) + ... + c
```

where `u` is the recorded PI output. The script searches autoregressive orders,
input orders, and input delays from 1 to 4, choosing the model with the lowest
chronological validation RMSE.

## Run

```matlab
addpath("matlab");
identify_plant_surrogate;
type("results\plant_surrogate_metrics.txt");
winopen("results\plant_surrogate_free_run.png");
```

The free-run metric is the critical acceptance test because it feeds predicted
voltage back into later predictions. A good one-step score combined with a poor
free-run score is not sufficient for closed-loop experiments.

## Reporting language

Use: "The controller was evaluated offline on measured simulation data and in
a closed-loop proof of concept using an identified ARX surrogate."

Do not use: "The NARX controller was validated on the original converter" or
"The controller is ready for hardware."
