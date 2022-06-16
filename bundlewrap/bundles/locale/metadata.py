defaults = {
    'locale': {
        'default': 'en_US.UTF-8',
        'installed': {
            'de_DE.UTF-8',
            'en_US.UTF-8',
            'nl_NL.UTF-8',
        },
    },
}


@metadata_reactor.provides(
    'locale/installed',
)
def ensure_default_is_installed(metadata):
    return {
        'locale': {
            'installed': {
                metadata.get('locale/default'),
            },
        },
    }
