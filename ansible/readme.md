# Ansible tips

## References

- https://gitlab.com/rgdacosta/ansible
- https://www.arthurkoziel.com/setting-up-vim-for-yaml/

## Yaml

### Multilines

```
include_newlines: |
        Example Company
        123 Main Street
        Atlanta, GA 30303

fold_newlines: >
        This is an example
        of a long string,
        that will become
        a single sentence once folded.
```

### Dictionaries

```
  name: svcrole
  svcservice: httpd
  svcport: 80
```
same as
```
  {name: svcrole, svcservice: httpd, svcport: 80}
```

### Lists

```
hosts:
  - servera
  - serverb
  - serverc
```
same as
```
hosts: [servera, serverb, serverc]
```

## Docs 

### Cli

```
ansible-navigator doc -l
ansible-navigator doc module_name
ansible-navigator -s doc module_name
ansible-navigator collections
```

### Online

- https://docs.ansible.com/ansible/latest/collections/index_module.html#ansible-builtin
- https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html


