import datetime
import json
import os
import sys

from airflow import DAG
from airflow.operators.bash_operator import BashOperator


def configure():

    def _parameterize(value, mapping):
        if isinstance(value, dict):
            return {
                key: _parameterize(value, mapping)
                for key, value in value.items()
            }
        if isinstance(value, list):
            return [_parameterize(value, mapping) for value in value]
        if isinstance(value, str):
            for pair in mapping.items():
                value = value.replace(*pair)
            return value
        return value

    # Extract the directory containing the current file
    path = os.path.dirname(__file__)
    # Extract the name of the current file without its extension
    name = os.path.splitext(os.path.basename(__file__))[0]
    # Load the configuration file corresponding to the extracted name
    config = os.path.join(path, 'configs', name + '.json')
    config = json.loads(open(config).read())
    # Replace all occurrences of “${ROOT}” with the current directory
    config = _parameterize(config, {'${ROOT}': path})
    return config


def construct(config):

    def _construct_graph(default_args, start_date, **options):
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d')
        return DAG(default_args=default_args, start_date=start_date, **options)

    def _construct_task(graph, name, code):
        return BashOperator(task_id=name, bash_command=code, dag=graph)

    # Construct an empty graph
    graph = _construct_graph(**config['airflow'])
    # Construct the specified tasks
    tasks = [_construct_task(graph, **task) for task in config['tasks']]
    tasks = dict([(task.task_id, task) for task in tasks])
    # Enforce the specified dependencies between the tasks
    for child, parent in config['dependencies']:
        tasks[parent].set_downstream(tasks[child])
    return graph


try:
    # Load an appropriate configuration file and construct a graph accordingly
    graph = construct(configure())
    if __name__ == '__main__':
        graph.cli()
except FileNotFoundError:
    # Exit without errors in case the current file has no configuration file
    pass
