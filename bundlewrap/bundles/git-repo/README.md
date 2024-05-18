# git-repo

Deploy a full git repo to a specific dir.

## metadata

```
{
  'git-repo': {
    '/path/on/node': {
      'repo':   'ssh://git@example.com:7999/test.git',
      'branch': 'master',
      'owner':  'ulf', # optional
      'submodule': True, # optional, init and update submodules
    },
  },
}
```
