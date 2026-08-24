# Simulink replay validation

Because neither the original DC-bus plant nor the physical sample period was
supplied, this model performs recorded-signal replay. It demonstrates that the
NARX block can replace the PI input-output mapping inside Simulink; it does not
demonstrate closed-loop stability.

## Prepare signals and generate the network

Run from the repository root:

```matlab
addpath("matlab");
prepare_simulink_replay;
gensim(netClosed, 1);
```

The `1` means one normalized sample, not one second.

To construct and save the complete diagram automatically after `gensim`, run:

```matlab
build_simulink_replay_model;
```

## Build the replay diagram

In the generated model, retain the neural-network subsystem and add:

1. A **From Workspace** block with data `narxReplayInput`.
2. A second **From Workspace** block with data `piReplayTarget`.
3. A **Subtract** block configured as `+-`.
4. A **Mux** block with two inputs.
5. A **Scope** block.
6. Three **To Workspace** blocks for the NARX output, PI target, and error.

Connect:

```text
narxReplayInput -> NARX Controller -> predicted output -----> Mux -> Scope
piReplayTarget ---------------------------------------------> Mux
piReplayTarget ----(+ Subtract -)---- predicted output
```

Configure the `To Workspace` variable names as:

- `simNarxOutput`
- `simPiTarget`
- `simReplayError`

Use `Timeseries` as the save format. Set model stop time to `30000`, solver type
to **Fixed-step**, and fixed-step size to `1`.

Save the model as:

```text
simulink/narx/narx_replay_validation.slx
```

## Required report statement

"The Simulink experiment replays recorded DC-bus signals through the trained
NARX controller and compares its output with the recorded PI output. Because
the original plant and physical sample time were unavailable, this experiment
validates behavioral replacement rather than closed-loop stability."
