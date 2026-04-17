def node_apply_end(repo, node, duration, interactive, result, **kwargs):
    if node.os not in node.OS_FAMILY_UNIX:
        return

    node.run(f'echo "{repo.revision}" > /var/lib/bundlewrap/last_apply_commit_id')
    node.run(f'echo "{repo.branch}" > /var/lib/bundlewrap/last_apply_branch')
