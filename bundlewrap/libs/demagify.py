import bwkeepass as keepass

def demagify(something):
    if isinstance(something, str):
        if something.startswith('!kee_user:'):
            return keepass.username(something[10:])
        elif something.startswith('!kee_pass:'):
            return keepass.password(something[10:])
        return something
    elif isinstance(something, dict):
        return {k:demagify(v) for k,v in something.items()}
    elif isinstance(something, list):
        return [demagify(i) for i in something]
    elif isinstance(something, set):
        return {demagify(i) for i in something}
    elif isinstance(something, tuple):
        return (demagify(i) for i in something)
    return something
