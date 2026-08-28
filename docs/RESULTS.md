# Results

## Accepted controller

The accepted model is a 64-unit stateful LSTM trained on 108,000 samples from
180 randomized episodes of the disclosed synthetic DC-bus benchmark.

## Final Simulink benchmark

- Model: `simulink/final/dc_bus_pi_vs_lstm.slx`
- Samples: 601
- PI voltage RMSE: 0.8005 V
- LSTM voltage RMSE: 0.7951 V
- LSTM RMSE change relative to PI: -0.670%
- PI voltage MAE: 0.4053 V
- LSTM voltage MAE: 0.4122 V
- PI peak error: 5.1515 V
- LSTM peak error: 4.7742 V

In the final Simulink demonstration, the LSTM slightly improves RMSE and peak
error compared with the PI expert on the same reference/load scenario.

## Unseen-episode command imitation

- Test episodes: 27
- Scored samples: 15,120
- RMSE: 0.4074
- MAE: 0.2568
- R-squared: 0.9235

This checks whether the LSTM can imitate the PI expert's command on synthetic
episodes not used during training.

## Independent closed-loop comparison

- Evaluation episodes: 20
- PI voltage RMSE: 0.7547 V
- LSTM voltage RMSE: 0.8491 V
- LSTM RMSE change relative to PI: +12.5%
- PI mean peak error: 4.4458 V
- LSTM mean peak error: 4.4619 V
- PI mean absolute command change: 0.0669
- LSTM mean absolute command change: 0.0280

Across randomized unseen scenarios, the LSTM maintained stable regulation and
nearly identical peak error while producing substantially smoother control. Its
average tracking RMSE was moderately worse, so the overall result supports
successful replacement rather than guaranteed superiority.

## Rejected experiments

- Original-data autoregressive neural controller: good teacher-forced accuracy,
  unstable closed-loop replay.
- Original-data fixed-window MLP: negative chronological test R-squared.
- Original-data LSTM: negative chronological test R-squared.
- ARX plant surrogate: negative free-run R-squared.

These failures demonstrate why missing plant variables and controller state
cannot be repaired merely by selecting a larger model.

## Scope

All successful closed-loop results apply only to the simplified first-order
synthetic benchmark. They do not establish switching-converter, hardware, or
original-system performance.
