import bwkeepass


@magic_string
def kee_user(arg):
    return bwkeepass.username(arg)

@magic_string
def kee_pass(arg):
    return bwkeepass.password(arg)

@magic_string
def decrypt(arg):
    return vault.decrypt(arg)
