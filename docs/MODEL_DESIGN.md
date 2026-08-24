# Model design

## Why NARX?

A PI controller is dynamic: its output depends on the present error and the
accumulated history of previous errors. A static neural network receiving only
one row cannot reproduce that memory reliably. NARX supplies temporal memory
through delayed external inputs and delayed controller outputs.

## Signals

Let:

- `r(k)` be `Vdc reference`
- `v(k)` be `Vdc Sensed`
- `e(k) = r(k) - v(k)` be the voltage error
- `u(k)` be `PI Output`

The learned controller approximates:

```text
u(k) = f(e(k-1), e(k-2), v(k-1), v(k-2), u(k-1), u(k-2))
```

The recorded `PI Input` is retained for auditing, but calculated voltage error
is used as the principal control input so the deployed model has a clear
physical interpretation.

## Initial architecture

- NARX network in open-loop form during supervised training
- Input delays: `[1 2]`
- Feedback delays: `[1 2]`
- Hidden layers: `[16 8]`
- Hidden activation: hyperbolic tangent sigmoid
- Output activation: linear
- Loss: mean squared error
- Trainer: Bayesian regularization (`trainbr`)

This is intentionally small enough for a five-day prototype. Larger networks
should be considered only if validation error shows underfitting.

## Data-splitting rule

Never randomly shuffle this time-series dataset. Use the first 70% for
training, the next 15% for validation, and the final 15% for testing. This
better represents deployment on future samples.

## Safety constraints

The AI output must pass through a Saturation block. Start with the observed PI
output limits `[-9.33386, 10.0503]`. During initial simulations, retain a
manual switch that can select the original PI controller.

## Limitation

The supplied reference voltage is always 300 V. Therefore, the network cannot
claim generalization to arbitrary voltage references until additional
simulations are generated with varied reference values, loads, source power,
and battery state of charge.
