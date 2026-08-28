# Stateful LSTM controller

The LSTM is the final candidate after diagnostic experiments showed that:

- a fixed-window MLP failed because its bounded window could not reconstruct
  the PI controller's longer internal state.
- original-data-only sequence training was not enough for closed-loop
  deployment because the supplied log did not include the full plant state.

The LSTM consumes only `PI Input` and `Vdc Sensed`. Its recurrent hidden state
provides memory without feeding the predicted controller output back as an
input.

## Training design

- Sequence-to-sequence regression
- 512 samples per chronological sequence
- 64 LSTM units
- 32-unit nonlinear projection
- Adam optimizer
- Manual normalization based only on training sequences
- Chronological 70/15/15 sequence split
- No shuffling

## Evaluation

The first 64 predictions of every test sequence are treated as state warm-up
and excluded from metrics. This rule is fixed before examining test results.

```matlab
train_lstm_controller;
evaluate_lstm_controller;
type("results\lstm_metrics.txt");
```

The controller is accepted for Simulink replay only if the unseen chronological
trace follows the target regimes and R-squared is positive. Closed-loop plant
stability still cannot be claimed because the physical plant was not supplied.
