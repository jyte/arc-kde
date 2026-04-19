#!/bin/sh

set -eu

repo_name="arc-kde"
repo_desc="Arc KDE"
repo_url="https://github.com/PapirusDevelopmentTeam/${repo_name}"

cat <<- BANNER



        aaa                          kk   kk   ddddd     eeeeeee
      aa   aa   rr rrrr     ccccc    kk kk     dd   dd   ee
      aaaaaaa   rrr       cc         kkk       dd   dd   eeeee
      aa   aa   rr        cc         kk kk     dd   dd   ee
      aa   aa   rr          ccccc    kk   kk   ddddd     eeeeeee


  ${repo_desc}
  ${repo_url}


BANNER

: "${PREFIX:=/usr}"
: "${TAG:=master}"
: "${UNINSTALL:=false}"
: "${USER_INSTALL:=false}"
: "${SOURCE_DIR:=}"

msg() {
    printf '=> %s\n' "$*" >&2
}

die() {
    printf '==> ERROR: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [ -n "${temp_file:-}" ] && [ -f "${temp_file}" ]; then
        rm -f "${temp_file}"
    fi
    if [ -n "${temp_dir:-}" ] && [ -d "${temp_dir}" ]; then
        rm -rf "${temp_dir}"
    fi
}

share_dir() {
    if [ "$USER_INSTALL" = "true" ]; then
        printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}"
    else
        printf '%s\n' "${DESTDIR:-}${PREFIX}/share"
    fi
}

require_writable_share_dir() {
    target="$(share_dir)"
    parent="$(dirname "$target")"

    if [ -d "$target" ] && [ ! -w "$target" ]; then
        die "${target} is not writable. Re-run with elevated privileges or set USER_INSTALL=true."
    fi

    if [ ! -d "$target" ] && [ ! -w "$parent" ]; then
        die "${parent} is not writable. Re-run with elevated privileges or set USER_INSTALL=true."
    fi
}

remove_path() {
    path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        rm -rf "$path"
        dir="$(dirname "$path")"
        while [ "$dir" != "/" ] && [ "$dir" != "." ]; do
            rmdir "$dir" 2>/dev/null || break
            dir="$(dirname "$dir")"
        done
    fi
}

download_source() {
    temp_file="$(mktemp)"
    temp_dir="$(mktemp -d)"

    msg "Downloading ${repo_desc} (${TAG}) ..."
    wget -O "$temp_file" "${repo_url}/archive/${TAG}.tar.gz"

    msg "Unpacking archive ..."
    tar -xzf "$temp_file" -C "$temp_dir"
    SOURCE_DIR="$temp_dir/${repo_name}-${TAG}"
}

resolve_source_dir() {
    if [ -n "$SOURCE_DIR" ]; then
        SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)
        return
    fi

    script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    if [ -d "$script_dir/plasma" ] && [ -d "$script_dir/wallpapers" ]; then
        SOURCE_DIR="$script_dir"
        return
    fi

    download_source
}

uninstall_theme() {
    target_root="$(share_dir)"
    msg "Removing ${repo_desc} from ${target_root} ..."

    remove_path "$target_root/aurorae/themes/Arc"
    remove_path "$target_root/aurorae/themes/Arc-Dark"
    remove_path "$target_root/color-schemes/Arc.colors"
    remove_path "$target_root/color-schemes/ArcDark.colors"
    remove_path "$target_root/konsole/Arc.colorscheme"
    remove_path "$target_root/konsole/ArcDark.colorscheme"
    remove_path "$target_root/konversation/themes/papirus"
    remove_path "$target_root/konversation/themes/papirus-dark"
    remove_path "$target_root/Kvantum/Arc"
    remove_path "$target_root/Kvantum/ArcDark"
    remove_path "$target_root/Kvantum/ArcDarker"
    remove_path "$target_root/plasma/desktoptheme/Arc-Dark"
    remove_path "$target_root/plasma/desktoptheme/Arc-Color"
    remove_path "$target_root/plasma/look-and-feel/com.github.varlesh.arc-dark"
    remove_path "$target_root/plasma/look-and-feel/com.github.varlesh.arc-darker"
    remove_path "$target_root/plasma/look-and-feel/com.github.varlesh.arc"
    remove_path "$target_root/wallpapers/Arc"
    remove_path "$target_root/wallpapers/Arc-Dark"
    remove_path "$target_root/wallpapers/Arc-Mountains"
    remove_path "$target_root/yakuake/skins/arc"
    remove_path "$target_root/yakuake/skins/arc-dark"
}

install_theme() {
    target_root="$(share_dir)"
    msg "Installing ${repo_desc} into ${target_root} ..."
    install -d "$target_root"
    cp -R \
        "$SOURCE_DIR/aurorae" \
        "$SOURCE_DIR/color-schemes" \
        "$SOURCE_DIR/konsole" \
        "$SOURCE_DIR/konversation" \
        "$SOURCE_DIR/Kvantum" \
        "$SOURCE_DIR/plasma" \
        "$SOURCE_DIR/wallpapers" \
        "$SOURCE_DIR/yakuake" \
        "$target_root"
}

fix_permissions() {
    target_root="$(share_dir)"
    msg "Normalizing installed file permissions ..."
    find "$target_root/aurorae" "$target_root/color-schemes" "$target_root/konsole" \
        "$target_root/konversation" "$target_root/Kvantum" "$target_root/plasma" \
        "$target_root/wallpapers" "$target_root/yakuake" \
        -type d -exec chmod a+rx {} + 2>/dev/null || true
    find "$target_root/aurorae" "$target_root/color-schemes" "$target_root/konsole" \
        "$target_root/konversation" "$target_root/Kvantum" "$target_root/plasma" \
        "$target_root/wallpapers" "$target_root/yakuake" \
        -type f -exec chmod a+r {} + 2>/dev/null || true
}

clear_cache() {
    cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
    msg "Clearing Plasma theme caches ..."
    rm -rf \
        "$cache_home/plasma-svgelements-Arc"* \
        "$cache_home/plasma_theme_Arc"*.kcache \
        "$cache_home/kpackage"* 2>/dev/null || true
    msg "Done."
}

trap cleanup EXIT HUP INT TERM

resolve_source_dir
require_writable_share_dir

if [ "$UNINSTALL" = "true" ]; then
    uninstall_theme
else
    uninstall_theme
    install_theme
    fix_permissions
fi

clear_cache
