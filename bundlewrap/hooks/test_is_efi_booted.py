from bundlewrap.exceptions import GracefulApplyException
from bundlewrap.utils.ui import io


def apply_start(repo, target, nodes, interactive=False, **kwargs):
    failed = set()
    for node in nodes:
        if not node.has_bundle("grub"):
            continue

        is_booted = node.is_efi_booted
        metadata = node.metadata.get("grub/efi")
        if is_booted != metadata:
            io.stderr(
                f"{node.name} has is_efi_booted {is_booted}, but metadata {metadata}"
            )
            failed.add(node.name)

    if failed:
        raise GracefulApplyException(
            f"These nodes have wrong GRUB EFI metadata (see above): {' '.join(sorted(failed))}"
        )
