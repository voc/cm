locale_needs = set()
for locale in sorted(node.metadata['locale']['installed']):
    actions[f'ensure_locale_{locale}_is_enabled'] = {
        'command': f"sed -i '/{locale}/s/^# *//g' /etc/locale.gen",
        'unless': f"grep -e '^{locale}' /etc/locale.gen",
        'triggers': {
            'action:locale-gen',
        },
        'needs': locale_needs,
    }
    locale_needs = {f'action:ensure_locale_{locale}_is_enabled'}

actions = {
    'locale-gen': {
        'triggered': True,
        'command': 'locale-gen',
    },
}
