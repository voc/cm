from json import dumps, loads

from bundlewrap.metadata import metadata_to_json
from bundlewrap.utils import Fault

from tomlkit import dumps as toml_dumps
from bundlewrap.utils.text import toml_clean


def resolve_faults(dictionary: dict) -> dict:
    return loads(metadata_to_json(dictionary))


def ensure_fault_or_none(maybe_fault):
    if maybe_fault is None or isinstance(maybe_fault, Fault):
        return maybe_fault

    return Fault(maybe_fault, lambda f: f, f=maybe_fault)


def join_faults(faults, by=' '):
    result = []
    id_list = []

    for item in faults:
        result.append(ensure_fault_or_none(item))

        if isinstance(item, Fault):
            id_list += item.id_list
        else:
            id_list.append(item)

    id_list += [
        'joined_by',
        by,
    ]

    return Fault(
        id_list,
        lambda o: by.join([i.value for i in o]),
        o=result,
    )


def dict_as_json(json):
    return Fault(
        'dict_as_json',
        lambda o: metadata_to_json(o) + '\n',
        o=json
    )


def dict_as_toml(json):
    return Fault(
        'dict_as_toml',
        lambda o: toml_clean(toml_dumps(resolve_faults(o), sort_keys=True)) + '\n',
        o=json
    )
