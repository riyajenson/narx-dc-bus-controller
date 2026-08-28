# Simulink Models

## `final/`

Contains the accepted PI-versus-LSTM benchmark:

```text
dc_bus_pi_vs_lstm.slx
```

This model runs two controllers against the same synthetic DC-bus reference and
load disturbance:

- PI expert controller
- LSTM neural controller

Run it from MATLAB with:

```matlab
addpath("matlab");
open_system("simulink/final/dc_bus_pi_vs_lstm.slx");
finalOut = sim("dc_bus_pi_vs_lstm");
summarize_final_simulink_run(finalOut);
```

## `baseline/`

Reserved for an original supplied Simulink plant if one becomes available.
No original converter plant was supplied for this project.
