# SSH tricks

## Keychain

```
keychain ~/.ssh/myrsaprivkey . ~/.keychain/$HOSTNAME-sh
```

## Sshfs

```
sshfs user@srv:~ ./remdir
```

## Query

```
ssh -Q help
```
