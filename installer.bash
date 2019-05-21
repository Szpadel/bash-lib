#!/usr/bin/env bash
import tmp

installer__dir=""
installer__uninstall_script=""
installer__files_dir=""
installer__sha_file=""
installer__name=""

installer::set_name() {
    installer__name="$1"
}

installer::_init() {
    if [ -z "$installer__dir" ];then
        tmp::create_persistent_dir installer__dir "uninstaller"
        installer__uninstall_script="$installer__dir/uninstall.bash"
        installer__sha_file="$installer__dir/expectations.sha256sum"
        installer__files_dir="$installer__dir/files"
        mkdir "$installer__files_dir"
        echo "#!/usr/bin/env bash" > $installer__uninstall_script
        chmod +x $installer__uninstall_script
        installer::_write_header
    fi
}

installer::_write_line() {
    installer::_init
    echo "$*" >> $installer__uninstall_script
}

installer::_write_header() {
    installer::_write_line 'set -e'
    # shellcheck disable=SC2016
    installer::_write_line 'cd $(dirname ${BASH_SOURCE[0]})'
    installer::_write_line '# This is autogenerated uninstaller/rollback script'
    installer::_write_line 
    installer::_write_line 'log() {'
    installer::_write_line '    echo "$*" >&2'
    installer::_write_line '}'
    installer::_write_line 
    installer::_write_line 'sum_failed() {'
    installer::_write_line '    log'
    installer::_write_line '    log "Some files does not have expected content"'
    installer::_write_line '    log "installed files were changed after installation"'
    installer::_write_line '    log "or uninstaller files were damaged"'
    installer::_write_line '    log "Another transaction could be performed after this one,"'
    installer::_write_line '    log "and it might need to be reverted first"'
    installer::_write_line '    log "Aborting to prevent potential damages"'
    installer::_write_line '    exit 1'
    installer::_write_line '}'
    installer::_write_line
    installer::_write_line 'sha256sum --quiet -c ./expectations.sha256sum >&2 || sum_failed'
    # shellcheck disable=SC2016
    installer::_write_line 'log "Asserted $(cat ./expectations.sha256sum |grep -v \"^$\" | wc -l) files"'
    installer::_write_line "log '${installer__name:-"Uninstall / Rollback"} started'"
    installer::_write_line
}

installer::_add_sha_item() {
    local dir="$1"
    local file="$2"
    (cd "$dir" && sha256sum "$file" >> $installer__sha_file)
}

installer::update_file() {
    local src="$1"
    local dst="$2"
    if ! [ -e "$dst" ] || ! diff -q "$src" "$dst" > /dev/null;then
        installer::copy_file "$src" "$dst"
    fi
}

installer::copy_file() {
    local src="$1"
    local dst="$2"
    installer::_init
    if ! [ -f "$src" ];then
        log::panic "Src isn't a file: $src"
    fi
    if ! [[ "$dst" =~ ^/.* ]];then
        log::warn "dst path: \`$dst\` should be absolute, changing to: \`$PWD/$dst\`"
        dst="$PWD/$dst"
    fi
    if [ -f "$dst" ];then
        local backup=""
        tmp::create_persistent_file backup "backup" "$installer__files_dir"
        cp "$dst" "$backup"
        local relative_backup="${backup##$installer__dir/}"
        installer::_add_sha_item "$installer__dir" "$relative_backup"
        installer::_write_line "log 'Restoring $dst'"
        installer::_write_line "cp -p '$relative_backup' '$dst'"
    elif ! [ -e "$dst" ];then
        installer::_write_line "log 'Removing $dst'"
        installer::_write_line "rm '$dst'"
    else
        log::panic "\`$dst\` isn't a regular file"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    installer::_add_sha_item "/" "$dst"
}

installer::add_uninstall_cmd() {
    local msg="$1"
    local cmd="$2"
    local eof=$((RANDOM+10000))
    installer::_write_line "log 'Executing: $msg'"
    installer::_write_line "bash <<$eof"
    installer::_write_line "$cmd"
    installer::_write_line "$eof"
}

installer::commit_uninstaller() {
    local target_path="$1"
    if [ -e "$target_path" ];then
        log::panic "Target already exists"
    fi
    installer::_init
    mkdir -p "$(dirname "$target_path")"
    installer::_add_sha_item "$installer__dir" "${installer__uninstall_script##$installer__dir/}"
    mv "$installer__dir" "$target_path"
    installer__dir=""
}


installer_test::test_e2e_success() {
    local test_src=""
    tmp::create_dir test_src
    echo "new1" > $test_src/example1
    echo "new2" > $test_src/example2
    chmod +x $test_src/example2

    local test_target=""
    tmp::create_dir test_target
    echo "test2" > $test_target/example2

    installer::set_name "Testing uninstaller"
    installer::copy_file "$test_src/example1" "$test_target/example1"
    installer::copy_file "$test_src/example2" "$test_target/example2"

    unit::assert_success [ -f "$test_target/example1" ]
    unit::assert_eq "$(cat "$test_target/example1")" "new1"

    unit::assert_success [ -x "$test_target/example2" ]
    unit::assert_eq "$(cat "$test_target/example2")" "new2"

    installer::add_uninstall_cmd "Example execution step, create example.log" "echo some logs > $test_target/example.log"

    installer::commit_uninstaller "$test_target/uninstaller"

    unit::assert_success [ -x "$test_target/uninstaller/uninstall.bash" ]
    unit::assert_success "$test_target/uninstaller/uninstall.bash"

    unit::assert_failed [ -e "$test_target/example1" ]
    unit::assert_eq "$(cat "$test_target/example2")" "test2"

    unit::assert_success [ -f "$test_target/example.log" ]
    unit::assert_eq "$(cat "$test_target/example.log")" "some logs"

    tmp::cleanup
}

installer_test::test_e2e_failed() {
    local test_src=""
    tmp::create_dir test_src
    echo "new1" > $test_src/example1
    echo "new2" > $test_src/example2
    chmod +x $test_src/example2

    local test_target=""
    tmp::create_dir test_target
    echo "test2" > $test_target/example2

    installer::set_name "Testing uninstaller"
    installer::copy_file "$test_src/example1" "$test_target/example1"
    installer::copy_file "$test_src/example2" "$test_target/example2"

    unit::assert_success [ -f "$test_target/example1" ]
    unit::assert_eq "$(cat "$test_target/example1")" "new1"

    unit::assert_success [ -x "$test_target/example2" ]
    unit::assert_eq "$(cat "$test_target/example2")" "new2"

    installer::commit_uninstaller "$test_target/uninstaller"

    echo "changed1" > $test_target/example1

    unit::assert_success [ -x "$test_target/uninstaller/uninstall.bash" ]
    unit::assert_failed "$test_target/uninstaller/uninstall.bash"
    
    unit::assert_success [ -f "$test_target/example1" ]
    unit::assert_eq "$(cat "$test_target/example1")" "changed1"

    unit::assert_success [ -x "$test_target/example2" ]
    unit::assert_eq "$(cat "$test_target/example2")" "new2"

    tmp::cleanup
}

installer_test::all() {
    unit::test installer_test::test_e2e_success
    unit::test installer_test::test_e2e_failed
}
