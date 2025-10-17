from bundlewrap.exceptions import BundleError


def test_node(repo, node, **kwargs):
    run_test(node)


def node_apply_start(repo, node, interactive=False, **kwargs):
    run_test(node)


def run_test(node):
    if not node.has_bundle("crs-worker"):
        return

    env = node.metadata.get("crs-worker/use_vaapi")
    worker = node.metadata.get("crs-worker/separate_vaapi_worker")

    if env and worker:
        raise BundleError(
            f"{node.name}: you have requested to have all crs worker scripts to use vaapi, but also a separate vaapi worker. This is most likely not what you want."
        )
