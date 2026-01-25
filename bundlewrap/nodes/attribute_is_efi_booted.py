@node_attribute
def is_efi_booted(node):
    return node.run("test -d /sys/firmware/efi/", may_fail=True).return_code == 0
