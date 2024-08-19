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
DEFAULT_MODEL=gpt-4o-mini # or gpt-4o, gpt-3.5-turbo, ...
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

## Save a session

Question #1:
```
(gpt) sgpt --chat mysessionname --code "Python webcrawler to list all the links of a website"
```

Result #1:
```
import requests
from bs4 import BeautifulSoup

url = 'https://www.example.com'
response = requests.get(url)
soup = BeautifulSoup(response.text, 'html.parser')

for link in soup.find_all('a'):
    print(link.get('href'))
```

Question #2 is same session:
```
(gpt) sgpt --chat mysessionname --code "website name is imdb.com"
```

Result #2:
```
import requests
from bs4 import BeautifulSoup

url = 'https://www.imdb.com'
response = requests.get(url)
soup = BeautifulSoup(response.text, 'html.parser')

for link in soup.find_all('a'):
    print(link.get('href'))
```

