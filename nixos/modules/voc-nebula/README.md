## How to manage the voc-nebula cluster

### Add new host
1. Add the host to `hosts.json`
2. Run ./sign.py to sign the new host's certificate
```
./sign.py --name yourhost.c3voc.de
```
The key and certificate are automatically stored in the encrypted secrets.yaml file.

### Rotate CA
Replace CA certificate manually in secrets.yaml. Then run
```
./sign.py --force
```
Which will re-sign all host certificates.