# MATLAB and Simulink guide

## Requirements

- MATLAB
- Deep Learning Toolbox
- Simulink
- The original DC-bus Simulink model

## 1. Train the controller

Open MATLAB, browse to the repository root, and run:

```matlab
addpath("matlab");
prepare_dataset;
train_narx_controller;
evaluate_narx_controller;
```

Expected generated files:

- `data/processed/dc_bus_prepared.mat`
- `models/narx_controller.mat`
- `results/test_predictions.csv`
- `results/regression.png`
- `results/prediction_trace.png`
- `results/metrics.txt`

## 2. Confirm the offline result

Before using Simulink, check that:

- test RMSE and MAE are acceptably small;
- test R-squared is close to 1;
- predicted output follows the measured PI output without obvious lag;
- the test period was not used for training.

Low imitation error is necessary, but it does not prove closed-loop stability.

## 3. Generate the neural-network Simulink block

Load the trained model:

```matlab
load("models/narx_controller.mat", "netClosed");
gensim(netClosed, 1);
```

Replace `1` with the actual controller sample time in seconds. MATLAB will
generate a Simulink representation of the network. Copy the generated neural
network block into a new subsystem named `NARX Controller`.

## 4. Connect it safely

1. Calculate `error = Vdc reference - Vdc sensed`.
2. Combine `error` and `Vdc sensed` using a Mux block, in that order.
3. Connect the two-element signal to the NARX block.
4. Add a Saturation block after the NARX output.
5. Set lower limit to `-9.33386` and upper limit to `10.0503`.
6. Connect the saturated output where the original PI output was connected.
7. Place a Manual Switch before the plant so you can choose PI or NARX.

Do not delete the PI block until all comparisons are complete.

## 5. Closed-loop tests

Run the PI and NARX controllers under identical conditions:

1. Nominal load.
2. Sudden load increase.
3. Sudden load decrease.
4. Source-voltage or source-power disturbance.
5. Measurement noise.
6. Parameter variation, if the model permits it.

Log `Vdc reference`, `Vdc sensed`, controller output, battery current, and time.

## 6. Final comparison

For both controllers calculate:

- voltage RMSE;
- maximum overshoot;
- settling time;
- steady-state error;
- integral absolute error;
- control effort and output variation.

The final claim should be that NARX replaces the PI controller only if the
closed-loop results remain stable and compare favorably across disturbances.
