# Simulink models

## `baseline/`

Place the original, unmodified DC-bus Simulink model here. Preserve this copy
so PI and NARX simulations can be run under identical conditions.

## `narx/`

Save the modified model containing the NARX controller here under a new name.
Do not overwrite the baseline model.

Before generating the neural-network block, record:

- model solver type and fixed/variable step size;
- PI block sample time;
- PI input and output signal dimensions;
- PI output limits;
- model stop time;
- signals used for voltage and controller-output logging.

Generate the block only after the controller sample time is known:

```matlab
load("models/narx_controller.mat", "netClosed");
gensim(netClosed, controllerSampleTime);
```

Connect `[voltage error; sensed DC voltage]` to the generated controller, then
apply output saturation and retain a PI/NARX Manual Switch during validation.
