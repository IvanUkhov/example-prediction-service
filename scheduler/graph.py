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

    path = os.path.dirname(__file__)
    name = os.path.splitext(os.path.basename(__file__))[0]
    config = os.path.join(path, 'configs', name + '.json')
    if os.path.exists(config):
        config = json.loads(open(config).read())
        return _parameterize(config, {'${ROOT}': path})


def construct(config):

    def _construct_graph(default_args, start_date, **options):
        start_date = datetime.datetime.strptime(start_date, '%Y-%m-%d')
        return DAG(default_args=default_args, start_date=start_date, **options)

    def _construct_task(graph, name, code):
        return BashOperator(task_id=name, bash_command=code, dag=graph)

    graph = _construct_graph(**config['airflow'])
    tasks = [_construct_task(graph, **task) for task in config['tasks']]
    tasks = dict([(task.task_id, task) for task in tasks])
    for child, parent in config['dependencies']:
        tasks[parent].set_downstream(tasks[child])
    return graph


config = configure()
if config is not None:
    graph = construct(config)
    if __name__ == '__main__':
        graph.cli()
