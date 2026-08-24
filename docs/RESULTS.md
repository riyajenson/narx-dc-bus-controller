# Results

## Accepted controller

The accepted model is a 64-unit stateful LSTM trained on 108,000 samples from
180 randomized episodes of the disclosed synthetic DC-bus benchmark.

### Unseen-episode command imitation

- Test episodes: 27
- Scored samples: 15,120
- RMSE: 0.4074
- MAE: 0.2568
- R-squared: 0.9235

### Independent closed-loop comparison

- Evaluation episodes: 20
- PI voltage RMSE: 0.7547 V
- LSTM voltage RMSE: 0.8491 V
- LSTM RMSE change relative to PI: +12.5%
- PI mean peak error: 4.4458 V
- LSTM mean peak error: 4.4619 V
- PI mean absolute command change: 0.0669
- LSTM mean absolute command change: 0.0280

The LSTM maintained stable regulation and nearly identical peak error while
producing substantially smoother control. Its tracking RMSE was moderately
worse, so the result supports successful replacement—not superiority.

## Rejected experiments

- Original-data NARX: good teacher-forced accuracy, unstable autoregressive
  Simulink replay.
- Original-data fixed-window MLP: negative chronological test R-squared.
- Original-data LSTM: negative chronological test R-squared.
- ARX plant surrogate: negative free-run R-squared.

These failures demonstrate why missing plant variables and controller state
cannot be repaired merely by selecting a larger model.

## Scope

All successful closed-loop results apply only to the simplified first-order
synthetic benchmark. They do not establish switching-converter, hardware, or
original-system performance.
