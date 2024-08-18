# Gnu Privacy Guard

## Gen

```
gpg --gen-key
gpg --list-key
```

## Export

```
gpg --export --armor bob@mydomain.net > bob_pub_key.asc
```

## Import

```
gpg --import bob_pub_key.asc
gpg --list-key
gpg --edit-key bob@mydomain.net # "I trust fully"
gpg --list-key
gpg --sign-key bob@mydomain.net # enter passphrase
gpg --list-key
```

## Encrypt

```
echo "This is a test" > secretfile.txt
gpg -e -r bob@mydomain.net secretfile.txt
```

## Decrypt

```
gpg -d secretfile.txt.gpg > secretdecrypt.txt # enter passphrase 
```

## Signature

### Send encrypted+signed

```
gpg --output fileencnsig.sig --sign file.txt # enter passphrase, encrypted+compressed
```

### Receive

```
gpg --verify fileencnsig.sig
gpg -d fileencnsig.sig > decrypted.txt
```

### Only sign

```
gpg --output sigedfile.dsig --detach-sign filetosign.txt # smaller
```

### Append signature

```
gpg --clearsign --output cleartextwithsig.txt file.txt
cat cleartextwithsig.txt
```


