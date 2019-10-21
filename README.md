# Example: Prediction Service

See “[A poor man’s orchestration of predictive models, or do it
yourself][article]” for further details.

## Usage

In order to build a Docker image and upload it to Container Registry, run

```bash
make build
```

In order to (1) start a Compute Engine instance for training a model, (2) wait
until completion, and (3) ensure that everything went well, run

```bash
make training-start training-wait training-check
```

In order to (1) start a Compute Engine instance for applying a trained model,
(2) wait until completion, and (3) ensure that everything went well, run

```bash
make application-start application-wait application-check
```

In order to schedule training and application using Airflow, run

```bash
git clone https://github.com/chain-rule/example-prediction-service.git "${AIRFLOW_HOME}/dags"
```

[article]: https://blog.ivanukhov.com/2019/07/01/orchestration.html
