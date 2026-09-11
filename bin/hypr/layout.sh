#!/bin/bash

# --- PATH RESOLUTION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/layout.conf"
AUTOSTART_FILE="${HOME}/.config/hypr/autostart.lua"
LOG_FILE="${HOME}/.cache/layout-engine.log"
PID_FILE="${HOME}/.cache/layout-engine.pid"

# --- CLEAN LOGGING ---
log() {
    local timestamp=$(date +'%H:%M:%S')
    echo "[${timestamp}] [$1] $2" | tee -a "${LOG_FILE}" >&2
}

# --- ENGINE UTILITIES ---
run_hypr() {
    if [[ "$1" != "dispatch" ]]; then
        hyprctl "$@" >> /dev/null 2>&1
        return
    fi

    shift
    local dispatcher="$1"
    shift

    case "$dispatcher" in
        focuswindow)
            hyprctl dispatch "hl.dsp.focus({ window = \"$1\" })" >> /dev/null 2>&1
            ;;
        movetoworkspacesilent)
            local target="$1"
            local workspace="${target%%,*}"
            local window="${target#*,}"
            hyprctl dispatch "hl.dsp.window.move({ workspace = \"$workspace\", window = \"$window\" })" >> /dev/null 2>&1
            ;;
        movewindow)
            hyprctl dispatch "hl.dsp.window.move({ direction = \"$1\" })" >> /dev/null 2>&1
            ;;
        layoutmsg)
            hyprctl dispatch "hl.dsp.layout([[${*}]])" >> /dev/null 2>&1
            ;;
        togglefloating)
            hyprctl dispatch 'hl.dsp.window.float()' >> /dev/null 2>&1
            ;;
        resizewindowpixel)
            local target_width="$(awk '{print $2}' <<< "$*")"
            local target_height="$(hyprctl activewindow -j | jq -r '.size[1] // 0')"
            hyprctl dispatch "hl.dsp.window.resize({ x = $target_width, y = $target_height })" >> /dev/null 2>&1
            ;;
        workspace)
            hyprctl dispatch "hl.dsp.focus({ workspace = \"$1\" })" >> /dev/null 2>&1
            ;;
        moveoutofgroup|togglegroup)
            hyprctl dispatch "hl.dsp.exec_raw([[$dispatcher $*]])" >> /dev/null 2>&1
            ;;
        *)
            log "WARN" "Unsupported Lua dispatcher: $dispatcher $*"
            return 1
            ;;
    esac
}

# === THE FIX: CACHED JSON DATA ===
# Instead of querying the socket every time, we read from a global variable
get_window_data() {
    local class="$1" ws="$2"
    echo "$CLIENTS_CACHE" | jq -c ".[] | select((.class | contains(\"$class\")) and .workspace.id == $ws)" | head -n 1
}

get_window_data_anyws() {
    local class="$1"
    echo "$CLIENTS_CACHE" | jq -c ".[] | select(.class | contains(\"$class\"))" | head -n 1
}

get_grouped_len() {
    local addr="$1"
    echo "$CLIENTS_CACHE" | jq -r ".[] | select(.address == \"$addr\") | (if .grouped != null then (.grouped | length) else 0 end)" | head -n 1
}

ensure_ungrouped() {
    local addr="$1"
    local grouped_len

    grouped_len=$(get_grouped_len "$addr")
    if [[ "$grouped_len" -gt 1 ]]; then
        log "ACTION" "Ungrouping $addr before move"
        run_hypr dispatch focuswindow "address:$addr"
        run_hypr dispatch moveoutofgroup
        sleep 0.1
    fi
}

ensure_tiled() {
    local addr="$1"
    local is_floating

    is_floating=$(echo "$CLIENTS_CACHE" | jq -r ".[] | select(.address == \"$addr\") | .floating" | head -n 1)
    if [[ "$is_floating" == "true" ]]; then
        log "ACTION" "Tiling $addr for grouping"
        run_hypr dispatch focuswindow "address:$addr"
        run_hypr dispatch togglefloating
        sleep 0.1
    fi
}

refresh_clients_cache() {
    CLIENTS_CACHE=$(hyprctl clients -j)
}

try_group_command() {
    local addr="$1"
    shift

    run_hypr dispatch "$@"
    refresh_clients_cache

    local grouped_len
    grouped_len=$(get_grouped_len "$addr")
    [[ "$grouped_len" -gt 1 ]]
}

move_into_group() {
    local addr="$1"
    local direction

    hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >> /dev/null 2>&1

    for direction in left right up down; do
        hyprctl dispatch "hl.dsp.window.move({ into_or_create_group = \"$direction\" })" >> /dev/null 2>&1
        refresh_clients_cache
        if [[ "$(get_grouped_len "$addr")" -gt 1 ]]; then
            return 0
        fi
    done

    return 1
}

get_monitor_data() {
    local ws="$1"
    local mon=$(echo "$MONITORS_CACHE" | jq -c ".[] | select(.activeWorkspace.id == $ws)" | head -n 1)
    [[ -z "$mon" ]] && mon=$(echo "$MONITORS_CACHE" | jq -c ".[0]")
    echo "$mon"
}

get_monitor_data_by_addr() {
    local addr="$1"
    local mon_id
    mon_id=$(echo "$CLIENTS_CACHE" | jq -r ".[] | select(.address == \"$addr\") | .monitor" | head -n 1)
    [[ -z "$mon_id" ]] && return
    echo "$MONITORS_CACHE" | jq -c ".[] | select(.id == $mon_id)" | head -n 1
}

wait_for_hyprctl() {
    local attempts=0 clients monitors

    while (( attempts < 80 )); do
        clients=$(hyprctl clients -j 2>/dev/null) || clients=""
        monitors=$(hyprctl monitors -j 2>/dev/null) || monitors=""

        if jq -e 'type == "array"' >/dev/null 2>&1 <<< "$clients" &&
           jq -e 'type == "array" and length > 0' >/dev/null 2>&1 <<< "$monitors"; then
            CLIENTS_CACHE="$clients"
            MONITORS_CACHE="$monitors"
            return 0
        fi

        attempts=$((attempts + 1))
        sleep 0.25
    done

    log "ERROR" "Hyprland IPC was not ready after 20 seconds"
    return 1
}

get_monitor_layout_width() {
    local mon_json="$1"
    local raw_w=$(echo "$mon_json" | jq -r '.width // 0')
    local scale=$(echo "$mon_json" | jq -r '.scale // 1')
    local reserved_right=$(echo "$mon_json" | jq -r '.reserved[1] // 0')
    local reserved_left=$(echo "$mon_json" | jq -r '.reserved[3] // 0')
    local scaled_w

    scaled_w=$(awk "BEGIN {printf \"%d\", ($raw_w / $scale)}")
    if [[ "$scaled_w" -le 0 ]]; then
        echo "$raw_w"
        return
    fi

    echo $((scaled_w - reserved_left - reserved_right))
}

# --- INITIALIZATION ---
declare -a APP_ORDER
declare -A ALIAS_MAP CMD_MAP WS_MAP FOCUS_RULES

while read -r line; do
    [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]] && continue
    read -ra args <<< "$line"
    case "${args[0]}" in
        "APP")
            APP_ORDER+=("${args[1]}")
            ALIAS_MAP["${args[1]}"]="${args[2]}"
            CMD_MAP["${args[1]}"]="${args[*]:3}"
            ;;
        "RATIO"|"GROUP"|"SPAWN")
            for app in "${args[@]:2}"; do WS_MAP["$app"]="${args[1]}"; done
            ;;
        "FOCUS")
            if [[ "${args[1]}" =~ ^[0-9]+$ ]]; then
                FOCUS_RULES["${args[1]}"]="${args[2]}"
            else
                al="${args[1]}" # FIX 1: Removed 'local' keyword
                FOCUS_RULES["${WS_MAP[$al]:-1}"]="$al"
            fi
            ;;
    esac
done < "${CONFIG_FILE}"

# === THE MISSING GENERATOR ===
if [[ "$1" == "generate" || "$1" == "--generate" ]]; then
    log "INFO" "Generating $AUTOSTART_FILE..."

    lua_quote() {
        local value="$1"
        value="${value//\\/\\\\}"
        value="${value//\"/\\\"}"
        value="${value//$'\n'/\\n}"
        printf '"%s"' "$value"
    }
    
    # Generate Lua startup calls while keeping layout decisions in layout.conf.
    {
        echo "-- Auto-generated by layout-engine for ${USER:-lanusri-}"
        echo "-- Source: ${CONFIG_FILE}"
        echo ""
        printf 'local TRACE_FILE = %s\n' "$(lua_quote "${HOME}/.cache/hypr-autostart.log")"
        cat <<'EOF'
local function trace(message)
    local file = io.open(TRACE_FILE, "a")
    if file then
        file:write(os.date("!%Y-%m-%dT%H:%M:%SZ ") .. message .. "\n")
        file:close()
    end
end

local function launch_if_enabled(command)
    local disable_path = (os.getenv("HOME") or "/home/l4n1skyy") .. "/.cache/disable_autostart"
    local file = io.open(disable_path, "r")
    if file then
        file:close()
        return
    end

    hl.exec_cmd(command)
end

trace("autostart.lua loaded")
EOF
        echo 'hl.on("hyprland.start", function()'
        echo '  trace("hyprland.start fired")'
        echo '  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'\''='\'' -f 1)")'
        echo '  hl.exec_cmd("dbus-update-activation-environment --systemd --all")'
        echo '  trace("launch requested: kanshi")'
        echo '  hl.exec_cmd(o.launch("kanshi"))'
        for alias in "${APP_ORDER[@]}"; do
            cmd="${CMD_MAP[$alias]}"
            printf '  trace(%s)\n' "$(lua_quote "launch requested: ${alias} -> ${cmd}")"
            printf '  launch_if_enabled(o.launch(%s))\n' "$(lua_quote "$cmd")"
        done
        echo '  trace("layout engine requested")'
        printf '  hl.exec_cmd(%s)\n' "$(lua_quote "${SCRIPT_DIR}/layout.sh --loop")"
        echo 'end)'
    } > "${AUTOSTART_FILE}"
    
    log "OK" "Generation complete. File saved to ${AUTOSTART_FILE}."
    exit 0
fi
# =============================

# --- PID FILE ---
mkdir -p "$(dirname "$PID_FILE")"
echo "$$" > "$PID_FILE"

# --- THE REACTIVE CORE ---
process_rule() {
    local type="$1" ws="$2" alias="$3" addr="$4" args=("${@:5}")
    local rule_id="${ws}_${type}_${alias}"

    [[ -n "${PROCESSED_RULES[$rule_id]}" ]] && return

    local mon_json=$(get_monitor_data_by_addr "$addr")
    [[ -z "$mon_json" ]] && mon_json=$(get_monitor_data "$ws")
    local mon_w=$(get_monitor_layout_width "$mon_json")
    local mon_x=$(echo "$mon_json" | jq -r '.x')
    local master_threshold=$((mon_x + 100))

    case "$type" in
        "SPAWN")
            PROCESSED_RULES["$rule_id"]=1
            ;;
        "RATIO")
            local move_dir="${args[0]}"
            local x_pct=$(echo "${args[2]}" | tr -d '%')
            local ratio_value

            # Wait until both ratio windows are present; adding the second window resets the split.
            local workspace_window_count
            workspace_window_count=$(echo "$CLIENTS_CACHE" | jq "[.[] | select(.workspace.id == $ws)] | length")
            if [[ "$workspace_window_count" -lt 2 ]]; then
                return
            fi

            ratio_value=$(awk "BEGIN {printf \"%.2f\", ($x_pct / 100.0)}")
            if [[ -z "$ratio_value" || ! "$ratio_value" =~ ^[0-9.]+$ ]]; then
                log "WARN" "WS $ws: Invalid ratio value '$x_pct' for $alias"
                return
            fi

            # Master layout controls the tiled split through its mfact layout message.
            # Apply the first ratio in each workspace; its companion rule describes the
            # remaining side of the same split.
            if [[ -z "${WS_MFACT_SET[$ws]}" ]]; then
                local target_ratio
                target_ratio=$(awk "BEGIN {printf \"%.2f\", $x_pct / 100.0}")
                log "DEBUG-RATIO" "WS $ws: Setting master split to ${target_ratio} (${x_pct}%)"
                run_hypr dispatch focuswindow "address:$addr"

                local current_width expected_width width_delta
                current_width=$(echo "$window_json" | jq -r '.size[0] // 0')
                expected_width=$(awk "BEGIN {printf \"%d\", $mon_w * $target_ratio}")
                width_delta=$((current_width - expected_width))
                (( width_delta < 0 )) && width_delta=$(( -width_delta ))
                if (( width_delta > 80 )); then
                    log "DEBUG-RATIO" "WS $ws: Target is not current master (${current_width}px vs ${expected_width}px); swapping"
                    run_hypr dispatch layoutmsg "swapwithmaster master"
                    sleep 0.2
                fi

                run_hypr dispatch layoutmsg "mfact exact ${target_ratio}"
                sleep 0.2
                WS_MFACT_SET["$ws"]=1
            else
                log "DEBUG-RATIO" "WS $ws: Companion ratio for $alias is ${x_pct}%; master split already set"
            fi
            PROCESSED_RULES["$rule_id"]=1
            ;;

        "GROUP")
            local moved_tail=0
            for tail in "${args[@]}"; do
                local t_class="${ALIAS_MAP[$tail]:-$tail}"
                local t_json=$(get_window_data "$t_class" "$ws")

                if [[ -z "$t_json" ]]; then
                    local any_json=$(get_window_data_anyws "$t_class")
                    if [[ -n "$any_json" ]]; then
                        local any_addr=$(echo "$any_json" | jq -r '.address // empty')
                        local any_ws=$(echo "$any_json" | jq -r '.workspace.id // empty')

                        if [[ -n "$any_addr" && "$any_ws" != "$ws" && -z "${MOVED_ADDR[$any_addr]}" ]]; then
                            log "ACTION" "WS $ws: Moving $tail from ws $any_ws"
                            ensure_ungrouped "$any_addr"
                            run_hypr dispatch movetoworkspacesilent "$ws,address:$any_addr"
                            MOVED_ADDR["$any_addr"]=1
                            moved_tail=1
                        fi
                    fi
                fi
            done

            [[ "$moved_tail" -eq 1 ]] && return

            local missing=0
            for tail in "${args[@]}"; do
                local t_class="${ALIAS_MAP[$tail]:-$tail}"
                local t_json=$(get_window_data "$t_class" "$ws")
                local t_addr=$(echo "$t_json" | jq -r '.address // empty')
                
                if [[ -n "$t_addr" ]]; then
                    ensure_tiled "$t_addr"
                    local is_grouped=$(echo "$t_json" | jq -r 'if .grouped != null then (.grouped | length) else 0 end')
                    
                    if [[ "$is_grouped" -lt 2 ]]; then
                        log "ACTION" "WS $ws: Forcing $tail into group"
                        run_hypr dispatch focuswindow "address:$t_addr"
                        sleep 0.1
                        run_hypr dispatch focuswindow "address:$t_addr"

                        local moved_ok=0
                        if move_into_group "$t_addr"; then
                            moved_ok=1
                        fi

                        # Fetch fresh data just for this verification
                        local post_json=$(hyprctl clients -j | jq -c ".[] | select(.address == \"$t_addr\")")
                        local post_grouped=$(echo "$post_json" | jq -r 'if .grouped != null then (.grouped | length) else 0 end')
                        
                        if [[ "$post_grouped" -lt 2 || "$moved_ok" -eq 0 ]]; then
                            log "WARN" "WS $ws: $tail escaped the group. Retrying..."
                            missing=$((missing + 1))
                        else
                            log "OK" "WS $ws: $tail successfully locked into group."
                        fi
                    fi
                else
                    missing=$((missing + 1))
                fi
            done
            [[ $missing -eq 0 ]] && PROCESSED_RULES["$rule_id"]=1
            ;;
    esac

    # INSTANT FOCUS
    if [[ -n "${PROCESSED_RULES[$rule_id]}" && "${FOCUS_RULES[$ws]}" == "$alias" ]]; then
        log "FOCUS" "WS $ws: Instant focus applied to $alias"
        run_hypr dispatch focuswindow "address:$addr"
    fi
}

# --- MAIN ENGINE LOOP ---
echo "=== SESSION START: $(date) ===" > "${LOG_FILE}"
start_time=$SECONDS
MAX_ATTEMPTS=3

wait_for_hyprctl || exit 1

for (( attempt=1; attempt<=MAX_ATTEMPTS; attempt++ )); do
    log "INFO" "--- RUNNING LAYOUT PASS $attempt ---"
    
    unset PROCESSED_RULES WS_GEOMETRY_LOCKED WS_GROUP_LOCKED MOVED_ADDR WS_RATIO_SPLIT_CREATED WS_MFACT_SET
    declare -A PROCESSED_RULES WS_GEOMETRY_LOCKED WS_GROUP_LOCKED MOVED_ADDR WS_RATIO_SPLIT_CREATED WS_MFACT_SET

    pass_start=$SECONDS
    while true; do
        all_rules_done=true
        
        # UPDATE CACHE ONCE PER LOOP
        CLIENTS_CACHE=$(hyprctl clients -j)
        MONITORS_CACHE=$(hyprctl monitors -j)
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]] && continue
            read -ra args <<< "$line"
            type="${args[0]}"
            [[ ! "$type" =~ ^(RATIO|GROUP|SPAWN)$ ]] && continue
            
            ws="${args[1]}"
            alias="${args[2]}"
            rule_id="${ws}_${type}_${alias}"
            
            if [[ -z "${PROCESSED_RULES[$rule_id]}" ]]; then
                all_rules_done=false
                class="${ALIAS_MAP[$alias]:-$alias}"
                window_json=$(get_window_data "$class" "$ws")

                if [[ -z "$window_json" ]]; then
                    any_json=$(get_window_data_anyws "$class")
                    if [[ -n "$any_json" ]]; then
                        any_addr=$(echo "$any_json" | jq -r '.address')
                        any_ws=$(echo "$any_json" | jq -r '.workspace.id')

                        if [[ "$any_ws" != "$ws" && -z "${MOVED_ADDR[$any_addr]}" ]]; then
                            log "ACTION" "WS $ws: Moving $alias from ws $any_ws"
                            ensure_ungrouped "$any_addr"
                            run_hypr dispatch movetoworkspacesilent "$ws,address:$any_addr"
                            MOVED_ADDR["$any_addr"]=1
                            continue
                        fi
                    fi
                fi

                if [[ -n "$window_json" ]]; then
                    addr=$(echo "$window_json" | jq -r '.address')
                    size=$(echo "$window_json" | jq -r '.size[0]')
                    [[ "$size" -gt 0 ]] && process_rule "$type" "$ws" "$alias" "$addr" "${args[@]:3}"
                fi
            fi
        done < "${CONFIG_FILE}"

        [[ "$all_rules_done" == "true" ]] || [[ $((SECONDS - pass_start)) -gt 60 ]] && break
        sleep 1.5
    done

    break
done

run_hypr dispatch workspace 1
notify-send -u normal -a "Omarchy" "Rice Deployed" "Layout Engine finished"
log "OK" "Engine Offline."
