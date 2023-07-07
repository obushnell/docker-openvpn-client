#!/usr/bin/env bats

setup() {
    CONFIG_PATH=/config
    export CONFIG_FILE_NAME=openvpn.conf
    unset CONFIG_FILE
    unset ALLOWED_SUBNETS
    unset AUTH_SECRET
    unset KILL_SWITCH
    export OPENVPN_DELAY=0
    run rm -r $CONFIG_PATH
    if [ "$1" == "config" ]; then
        run mkdir $CONFIG_PATH && touch $CONFIG_PATH/$CONFIG_FILE_NAME
    fi
}

# Tests for entry.sh

@test "OpenVPN configuration file found" {
    setup config

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config" ]
    [ "${lines[2]}" = "Done" ]
}

@test "OpenVPN delay is respected" {
    setup config
    export OPENVPN_DELAY=1

    run time -p entry.sh 2> time_output.txt

    execution_time=$(grep -Eo 'user [0-9]+\.[0-9]+' time_output.txt | awk '{print $2}')
    [ $(( $(echo "$execution_time > 0.5" | bc -l) )) ]
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config" ]
    [ "${lines[2]}" = "Done" ]
}

@test "OpenVPN ovpn file found" {
    setup
    export CONFIG_FILE_NAME=openvpn.ovpn
    run mkdir $CONFIG_PATH && touch $CONFIG_PATH/$CONFIG_FILE_NAME

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config" ]
    [ "${lines[2]}" = "Done" ]
}

@test "Custom config file found" {
    setup
    export CONFIG_FILE_NAME=something.txt
    export CONFIG_FILE=$CONFIG_FILE_NAME
    run mkdir $CONFIG_PATH && touch $CONFIG_PATH/$CONFIG_FILE_NAME

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config" ]
    [ "${lines[2]}" = "Done" ]
}

@test "KILL_SWITCH defined but not 'true'" {
    setup config

    kill_switch_values=("false" "f" "no" "n" "0" "off" "disable" "disabled")

    for value in "${kill_switch_values[@]}"; do
        export KILL_SWITCH="$value"

        run entry.sh

        [ "$status" -eq 0 ]
        [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
        [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config" ]
        [ "${lines[2]}" = "Done" ]
    done
}

@test "KILL_SWITCH enabled lowercase" {
    setup config

    kill_switch_values=("true" "t" "yes" "y" "1" "on" "enable" "enabled")

    for value in "${kill_switch_values[@]}"; do
        export KILL_SWITCH="$value"

        run entry.sh

        [ "$status" -eq 0 ]
        [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
        [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh ''" ]
        [ "${lines[2]}" = "Done" ]
    done
}

@test "KILL_SWITCH enabled uppercase" {
    setup config

    kill_switch_values=("TRUE" "T" "YES" "Y" "ON" "ENABLE" "ENABLED")

    for value in "${kill_switch_values[@]}"; do
        export KILL_SWITCH="$value"

        run entry.sh

        [ "$status" -eq 0 ]
        [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
        [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh ''" ]
        [ "${lines[2]}" = "Done" ]
    done
}

@test "KILL_SWITCH enabled mixed case" {
    setup config

    kill_switch_values=("EnAbLe" "eNaBlEd" "Yes" "True")

    for value in "${kill_switch_values[@]}"; do
        export KILL_SWITCH="$value"

        run entry.sh

        [ "$status" -eq 0 ]
        [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
        [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh ''" ]
        [ "${lines[2]}" = "Done" ]
    done
}

@test "KILL_SWITCH with ALLOWED_SUBNETS" {
    setup config

    export KILL_SWITCH=true
    export ALLOWED_SUBNETS=10.0.0.0/16

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh '$ALLOWED_SUBNETS'" ]
    [ "${lines[2]}" = "Done" ]
}

@test "KILL_SWITCH with ALLOWED_SUBNETS alternate" {
    setup config

    export KILL_SWITCH=true
    export ALLOWED_SUBNETS=192.168.15.0/24

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh '$ALLOWED_SUBNETS'" ]
    [ "${lines[2]}" = "Done" ]
}

@test "AUTH_SECRET enabled" {
    setup config

    export AUTH_SECRET=auth_secret

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --auth-user-pass /run/secrets/$AUTH_SECRET" ]
    [ "${lines[2]}" = "Done" ]
}

@test "AUTH_SECRET alternate" {
    setup config

    export AUTH_SECRET=secret_auth

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --auth-user-pass /run/secrets/$AUTH_SECRET" ]
    [ "${lines[2]}" = "Done" ]
}

@test "KILL_SWITCH and AUTH_SECRET enabled" {
    setup config

    export KILL_SWITCH=true
    export AUTH_SECRET=auth_secret

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh '' --auth-user-pass /run/secrets/$AUTH_SECRET" ]
    [ "${lines[2]}" = "Done" ]
}

@test "KILL_SWITCH, ALLOWED_SUBNETS, and AUTH_SECRET enabled" {
    setup config

    export KILL_SWITCH=true
    export ALLOWED_SUBNETS=10.0.0.0/24
    export AUTH_SECRET=auth_secret

    run entry.sh

    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "using openvpn configuration file: $CONFIG_PATH/$CONFIG_FILE_NAME" ]
    [ "${lines[1]}" = "--config $CONFIG_PATH/$CONFIG_FILE_NAME --cd /config --route-up /usr/local/bin/killswitch.sh '$ALLOWED_SUBNETS' --auth-user-pass /run/secrets/$AUTH_SECRET" ]
    [ "${lines[2]}" = "Done" ]
}

@test "No config folder" {
    setup

    run entry.sh

    [ "$status" -ne 0 ]
    [ "${lines[0]}" = "no openvpn configuration file found" ]
}

@test "No config folder with specified config file" {
    setup
    export CONFIG_FILE_NAME=my.conf
    export CONFIG_FILE=$CONFIG_FILE_NAME

    run entry.sh

    [ "$status" -ne 0 ]
    [ "${lines[0]}" = "no openvpn configuration file found" ]
}
