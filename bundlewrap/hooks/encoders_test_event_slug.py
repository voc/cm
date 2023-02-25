from os import environ

from bundlewrap.utils.ui import io
from bundlewrap.utils.text import red, blue, bold, wrap_question
from bundlewrap.exceptions import SkipNode


def node_apply_start(repo, node, interactive=False, **kwargs):
    if not node.has_bundle('encoder-common'):
        return

    if environ.get('BW_SKIP_TEST_EVENT_SLUG', '0') == '1':
        return

    event_slug = node.metadata.get('event/slug')

    if event_slug == 'XYZ':
        if interactive:
            if not io.ask(
                wrap_question(
                    red('hooks/encoders_test_event_slug'),
                    '\n'.join([
                        'event/slug is not set!',
                        'Please make sure you\'re using the correct event configuration.'
                        'If you choose "no" here, the node will get skipped in this apply.'
                    ]),
                    'Apply anyways?',
                    prefix='{} {}'.format(
                        blue('?'),
                        bold(node.name),
                    ),
                ),
                False,
            ):
                raise SkipNode('Declined in hooks/encoders_test_event_slug because of missing event slug')
        else:
            io.stderr(
                '{x}  {node}  has {no} event slug set! Please make sure you\'re using the correct event configuration!'.format(
                    x=red('✘'),
                    node=node.name,
                    no=bold('no'),
                )
            )
