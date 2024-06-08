from base64 import b64decode, b64encode
from functools import lru_cache
from hashlib import sha3_224

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    Encoding,
    NoEncryption,
    PrivateFormat,
    PublicFormat,
)

from bundlewrap.utils import Fault


@lru_cache(maxsize=None)
def generate_ed25519_private_key(username, node):
    return Fault(
        f"private key {username}@{node.name}",
        lambda username, node: _generate_ed25519_private_key(username, node),
        username=username,
        node=node,
    )


@lru_cache(maxsize=None)
def generate_ed25519_public_key(username, node):
    return Fault(
        f"public key {username}@{node.name}",
        lambda username, node: _generate_ed25519_public_key(username, node),
        username=username,
        node=node,
    )


def _generate_ed25519_private_key(username, node):
    privkey_bytes = Ed25519PrivateKey.from_private_bytes(_secret(username, node))

    nondeterministic_privatekey = privkey_bytes.private_bytes(
        encoding=Encoding.PEM,
        format=PrivateFormat.OpenSSH,
        encryption_algorithm=NoEncryption(),
    ).decode()

    # get relevant lines from string
    nondeterministic_bytes = b64decode(
        "".join(nondeterministic_privatekey.split("\n")[1:-2])
    )

    # sanity check
    if nondeterministic_bytes[98:102] != nondeterministic_bytes[102:106]:
        raise Exception("checksums should be the same: whats going on here?")

    # replace random bytes with deterministic values
    random_bytes = sha3_224(_secret(username, node)).digest()[0:4]
    deterministic_bytes = (
        nondeterministic_bytes[:98]
        + random_bytes
        + random_bytes
        + nondeterministic_bytes[106:]
    )

    # reassemble file
    deterministic_privatekey = (
        "\n".join(
            [
                "-----BEGIN OPENSSH PRIVATE KEY-----",
                b64encode(deterministic_bytes).decode(),
                "-----END OPENSSH PRIVATE KEY-----",
            ]
        )
        + "\n"
    )

    return deterministic_privatekey


def _generate_ed25519_public_key(username, node):
    return (
        Ed25519PrivateKey.from_private_bytes(_secret(username, node))
        .public_key()
        .public_bytes(
            encoding=Encoding.OpenSSH,
            format=PublicFormat.OpenSSH,
        )
        .decode()
        + f" {username}@{node.name}"
    )


@lru_cache(maxsize=None)
def _secret(username, node):
    return b64decode(
        str(
            node.repo.vault.random_bytes_as_base64_for(
                f"{username}@{node.name}", length=32
            )
        )
    )
