# Example Prediction Service

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
git clone https://github.com/IvanUkhov/example-prediction-service.git "${AIRFLOW_HOME}/dags"
```
