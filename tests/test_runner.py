import os
from pathlib import Path
from glob import glob
from subprocess import CalledProcessError
import logging
import sys

from cocotb.logging import SimLogFormatter
from cocotb_tools.runner import get_runner

from testbenches import get_toplevels

__REPO_ROOT = Path(__file__).resolve().parent.parent


SIM = os.getenv('SIM', 'ghdl')
COCOTB_TOPLEVEL = 'topic_example_add'


def test_runner():
    hdlr = logging.StreamHandler(sys.stdout)
    hdlr.setFormatter(SimLogFormatter())

    logger = logging.getLogger('test_runner')
    logger.addHandler(hdlr)
    logger.setLevel(logging.DEBUG)

    sources = glob(str(__REPO_ROOT / 'src/hdl/**/*.vhd'),
                   root_dir=__REPO_ROOT, recursive=True)

    if len(sources) > 0:
        logger.debug(f'Found {len(sources)} sources:')
        for source in sources:
            logger.debug(f'    > {source}')
    else:
        logger.error('No sources found')
        exit(1)

    runner = get_runner(SIM)

    for tl in get_toplevels():
        logger.info(f'Found tests for toplevel \"{tl.name}\"')

        runner.build(
            sources=sources,
            hdl_toplevel=tl.name,
            always=True,
            build_args=['--std=08'],
        )

        runner.test(
            hdl_toplevel=tl.name,
            hdl_toplevel_lang='vhdl',
            test_module=f'testbenches.{tl.name},',
            test_args=['--std=08'],
            gui=False,
        )


if __name__ == '__main__':
    test_runner()
