#!/usr/bin/env python3
import json, os, sys

status_path = os.path.expanduser("~/.config/pomoru/status.json")
pid_path = os.path.expanduser("~/.config/pomoru/instance.pid")


def local_pomoru_running() -> bool:
    try:
        with open(pid_path) as f:
            pid = int(f.read().strip())
    except Exception:
        return False

    try:
        os.kill(pid, 0)
        return True
    except Exception:
        # Process not found, clean up the stale PID file
        try:
            os.remove(pid_path)
        except Exception:
            pass
        return False


# Always return some output to ensure the module stays visible
try:
    # Check if status file exists and process is running
    status_exists = os.path.exists(status_path)
    is_running_instance = local_pomoru_running()

    # If status file doesn't exist or process isn't running, show inactive state
    if not status_exists or not is_running_instance:
        # Clean up PID file if process is not running but PID file exists
        if not is_running_instance and os.path.exists(pid_path):
            try:
                os.remove(pid_path)
            except Exception:
                pass

        print(
            json.dumps(
                {
                    "text": "󰔛 00:00",
                    "class": "pomoru-inactive",
                    "tooltip": "pomoru: not running\n00:00",
                }
            )
        )
        sys.exit(0)

    # Process is running and status file exists
    with open(status_path) as f:
        s = json.load(f)

    mode = s.get("mode", "work")
    running = s.get("running", False)
    time_str = s.get("time_remaining", "")
    task = s.get("current_task")
    task_text = None
    if task and isinstance(task, dict):
        task_text = task.get("title", "")

    icon = "󰏤"

    if mode == "work":
        label = task_text or "Focus"
        cls = "pomoru-work"
    elif mode == "short_break":
        label = "rest"
        cls = "pomoru-break"
    else:
        label = "long rest"
        cls = "pomoru-long-break"

    # Use requested glyphs for running/stopped states
    # Running: 󱎫  Stopped: 󰔛
    running_icon = "󱎫"
    stopped_icon = "󰔛"

    icon = running_icon if running else stopped_icon
    text = f"{icon} {time_str}"
    tooltip_parts = [f"{mode.replace('_', ' ')} — {time_str}", "running" if running else "paused"]
    if task_text:
        tooltip_parts.append(task_text)
    tooltip = "\n".join(tooltip_parts)
    module_class = cls if running else f"{cls}-paused"
    out = {"text": text, "class": module_class, "tooltip": tooltip}
    print(json.dumps(out))

except Exception as e:
    # If any error occurs, show the inactive state to ensure module remains visible
    print(
        json.dumps(
            {
                "text": "󰔛 00:00",
                "class": "pomoru-error",
                "tooltip": f"pomoru: error occurred - {str(e)}",
            }
        )
    )
    sys.exit(0)