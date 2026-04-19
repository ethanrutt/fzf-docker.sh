# The MIT License (MIT)
#
# fzf-docker - fuzzy finder for Docker resources
# Inspired by fzf-git.sh by Junegunn Choi
#
# Usage:
#   source fzf-docker.sh
#
# Keybindings (CTRL-O prefix):
#   CTRL-O CTRL-T  Containers
#   CTRL-O CTRL-I  Images
#   CTRL-O CTRL-V  Volumes
#   CTRL-O CTRL-N  Networks
#   CTRL-O ?       List bindings

# shellcheck disable=SC2039
[[ $0 == - ]] && return

__fzf_docker_color() {
  if [[ -n $NO_COLOR ]]; then
    echo never
  else
    echo "${FZF_DOCKER_COLOR:-always}"
  fi
}

__fzf_docker_pager() {
  local pager
  pager="${FZF_DOCKER_PAGER:-${PAGER:-less}}"
  echo "$pager"
}

if [[ $1 == --list ]]; then
  shift
  if [[ $# -ge 1 ]]; then
    case "$1" in
      containers)
        echo 'ALT-A (show all, including stopped)'
        docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}'
        ;;
      all-containers)
        echo '(including stopped)'
        docker ps -a --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}'
        ;;
      images)
        docker images --format 'table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}'
        ;;
      volumes)
        docker volume ls --format 'table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}'
        ;;
      networks)
        docker network ls --format 'table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}'
        ;;
      *) exit 1 ;;
    esac
  fi
fi

if [[ $- =~ i ]] || [[ $1 = --run ]]; then # ----------------------------------

if [[ $__fzf_docker_fzf ]]; then
  eval "$__fzf_docker_fzf"
else
  _fzf_docker_fzf() {
    fzf --height 50% --tmux 90%,70% \
      --layout reverse --multi --min-height 20+ --border \
      --no-separator --header-border horizontal \
      --border-label-pos 2 \
      --color 'label:blue' \
      --preview-window 'right,50%' --preview-border line \
      --bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
  }
fi

_fzf_docker_check() {
  docker info > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && tmux display-message "Docker is not running or not accessible"
  return 1
}

__fzf_docker=${BASH_SOURCE[0]:-${(%):-%x}}
__fzf_docker=$(readlink -f "$__fzf_docker" 2> /dev/null || /usr/bin/ruby --disable-gems -e 'puts File.expand_path(ARGV.first)' "$__fzf_docker" 2> /dev/null)

_fzf_docker_containers() {
  _fzf_docker_check || return
  bash "$__fzf_docker" --list containers |
  _fzf_docker_fzf --ansi \
    --border-label '🐳 Containers ' \
    --header-lines 2 \
    --preview "docker logs --tail 20 {1}" \
    --bind "alt-a:change-border-label(🐳 All containers)+reload:bash \"$__fzf_docker\" --list all-containers" \
    "$@" |
  awk '{print $1}'
}

_fzf_docker_images() {
  _fzf_docker_check || return
  bash "$__fzf_docker" --list images |
  _fzf_docker_fzf --ansi \
    --border-label '📦 Images ' \
    --header-lines 1 \
    --preview "docker history --no-trunc {1}" \
    "$@" |
  awk '{print $1}'
}

_fzf_docker_volumes() {
  _fzf_docker_check || return
  bash "$__fzf_docker" --list volumes |
  _fzf_docker_fzf --ansi \
    --border-label '💾 Volumes ' \
    --header-lines 1 \
    --preview "docker volume inspect {1} 2>/dev/null" \
    "$@" |
  awk '{print $1}'
}

_fzf_docker_networks() {
  _fzf_docker_check || return
  bash "$__fzf_docker" --list networks |
  _fzf_docker_fzf --ansi \
    --border-label '🌐 Networks ' \
    --header-lines 1 \
    --preview "docker ps --filter network={1} --format 'table {{.Image}}\t{{.Names}}\t{{.ID}}'" \
    "$@" |
  awk '{print $1}'
}

_fzf_docker_list_bindings() {
  cat <<'EOF'

CTRL-O ? to show this list
CTRL-O CTRL-T for Containers
CTRL-O CTRL-I for Images
CTRL-O CTRL-V for Volumes
CTRL-O CTRL-N for Networks
EOF
}

fi # --------------------------------------------------------------------------

if [[ $1 = --run ]]; then
  shift
  type=$1
  shift
  eval "_fzf_docker_$type" "$@"

elif [[ $- =~ i ]]; then # ----------------------------------------------------
if [[ -n "${BASH_VERSION:-}" ]]; then
  __fzf_docker_init() {
    bind -m emacs-standard '"\er":  redraw-current-line'
    bind -m emacs-standard '"\C-z": vi-editing-mode'
    bind -m vi-command     '"\C-z": emacs-editing-mode'
    bind -m vi-insert      '"\C-z": emacs-editing-mode'

    # Unbind CTRL-O so it can be used as a prefix key
    bind -m emacs-standard -r '\C-o'

    local pair key func
    for pair in "$@"; do
      if [[ $pair == '?'* ]]; then
        func=${pair#'?'}
        bind -x "\"\C-o?\": _fzf_docker_$func"
        continue
      fi
      key=${pair%%:*}
      func=${pair#*:}
      bind -m emacs-standard '"\C-o\C-'$key'": " \C-u \C-a\C-k`_fzf_docker_'$func'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-o\C-'$key'": "\C-z\C-o\C-'$key'\C-z"'
      bind -m vi-insert      '"\C-o\C-'$key'": "\C-z\C-o\C-'$key'\C-z"'
      bind -m emacs-standard '"\C-o'$key'":    " \C-u \C-a\C-k`_fzf_docker_'$func'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-o'$key'":    "\C-z\C-o'$key'\C-z"'
      bind -m vi-insert      '"\C-o'$key'":    "\C-z\C-o'$key'\C-z"'
    done
  }
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  __fzf_docker_join() {
    local item
    while read -r item; do
      echo -n -E "${(q)${(Q)item}} "
    done
  }

  __fzf_docker_init() {
    setopt localoptions no_glob
    local m pair key func
    for pair in "$@"; do
      if [[ ${pair[1]} == "?" ]]; then
        func=${pair:1}  # strip leading ?
        eval "fzf-docker-$func-widget() { zle -M '$(_fzf_docker_list_bindings)' }"
        eval "zle -N fzf-docker-$func-widget"
        for m in emacs vicmd viins; do
          eval "bindkey -M $m '^o?' fzf-docker-$func-widget"
        done
        continue
      fi
      key=${pair%%:*}
      func=${pair#*:}
      eval "fzf-docker-$func-widget() { local result=\$(_fzf_docker_$func | __fzf_docker_join); zle reset-prompt; LBUFFER+=\$result }"
      eval "zle -N fzf-docker-$func-widget"
      for m in emacs vicmd viins; do
        eval "bindkey -M $m '^o^$key' fzf-docker-$func-widget"
        eval "bindkey -M $m '^o$key' fzf-docker-$func-widget"
      done
    done
  }
fi

# key:function pairs — key is the letter after CTRL-O
__fzf_docker_init \
  t:containers \
  i:images \
  v:volumes \
  n:networks \
  '?list_bindings'

fi # --------------------------------------------------------------------------
