# fzf-docker.sh

Heavily inspired by [fzf-git.sh](https://github.com/junegunn/fzf-git.sh)

bash and zsh key bindings for docker objects, powered by [fzf](https://github.com/junegunn/fzf).

## Installation

1. clone

```sh
git clone https://github.com/ethanrutt/fzf-docker.sh.git "$HOME/.fzf-docker"
```

2. add to your `.bashrc` or `.zshrc`

```sh
[ -d "$HOME/.fzf-docker" ] && source "$HOME/.fzf-docker/fzf-docker.sh"
```

## Usage

### List of bindings

* <kbd>CTRL-O</kbd><kbd>?</kbd> to show this list
* <kbd>CTRL-O</kbd><kbd>CTRL-T</kbd> for Con**T**ainers
* <kbd>CTRL-O</kbd><kbd>CTRL-I</kbd> for **I**mages
* <kbd>CTRL-O</kbd><kbd>CTRL-V</kbd> for **V**olumes
* <kbd>CTRL-O</kbd><kbd>CTRL-N</kbd> for **N**etworks

> [!WARNING]
> in bash, <kbd>CTRL-O</kbd> executes the last command in your history. If you
> use that binding, you will lose it with this program
