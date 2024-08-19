# ShellGPT

## Install

```
dnf install python3-virtualenv
python3 -m venv gpt
cd gpt
source bin/activate
(gpt) pip3 install shell-gpt
```

## OpenAI key

In `~/.bashrc`:
```
echo 'export OPENAI_API_KEY=someverylongstring' >> ~/.bashrc
. ~/.bashrc
env # check
```
or in `~/.config/shell_gpt/.sgptrc`:
```
DEFAULT_MODEL=gpt-4o # or gpt-4o-mini, gpt-3.5-turbo, ...
OPENAI_API_KEY=someverylongstring
```

Pricing: https://openai.com/api/pricing/

## Test

In the virtual environment:
```
(gpt) sgpt --help
(gpt) sgpt "How to create a user account"
(gpt) sgpt "How to make a new SSH key pair"
(gpt) sgpt "How to change SSH default port"
```
