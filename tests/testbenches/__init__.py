from pkgutil import iter_modules
from pathlib import Path
from dataclasses import dataclass


@dataclass
class TestBenchModule:
    name: str


__MODULE_PATH = Path(__file__).resolve().parent


def get_toplevels() -> list[TestBenchModule]:
    submodules = []

    for sm in iter_modules([str(__MODULE_PATH)]):
        submodules.append(TestBenchModule(sm.name))

    return submodules
