# Ansible tips

## References

- https://gitlab.com/rgdacosta/ansible
- https://www.arthurkoziel.com/setting-up-vim-for-yaml/

### Vim config

```
sudo dnf install vim-enhanced

mkdir -p ~/github
cd ~/github

git clone https://github.com/vim/vim.git
git clone https://gitlab.com/rgdacosta/classroom_env
git clone https://github.com/Yggdroot/indentLine.git
git clone https://github.com/pedrohdz/vim-yaml-folds.git
git clone https://github.com/dense-analysis/ale.git

cp -r ale ~/.vim/bundle/
cp -r vim-yaml-folds ~/.vim/bundle/
cp -r indentLine/ ~/.vim/bundle/
wget https://tpo.pe/pathogen.vim -O ~/.vim/autoload/pathogen.vim

pip3 install yamllint
cp classroom_env/files/vimrc ~/.vimrc
cp classroom_env/files/config ~/.config/yamllint/config
```

Conpile Vim:
```
cd ~/github/vim
./configure --with-features=huge --enable-python3interp=yes --with-python3-config-dir=$(python3.12-config --configdir)
make
sudo make install
```

YCM server error (shoudn't happen):
```
cd ~/.vim/bundle/youcompleteme/
python3 install.py
```

### Bash config

```
export LESS='-X'
export HISTTIMEFORMAT="%F %T "
PROMPT_COMMAND="$PROMPT_COMMAND; history -a; history -n"

source /usr/share/git-core/contrib/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export PROMPT_COMMAND='PS1="[\u@\h \W]$(git_ps1)\\\$ "'
export GIT_PAGER=/usr/bin/cat
```

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


