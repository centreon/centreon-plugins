import subprocess
import time
import os
from robot.api.deco import keyword
import re

connector = None

class ConnectorLibrary:
    def __init__(self):
        self.process = None

    def ctn_start_connector(self, command=["/usr/lib64/centreon-connector/centreon_connector_perl", "--log-file=/tmp/connector.log", "--debug"]):
        if self.process is None or self.process.poll() is not None:
            self.process = subprocess.Popen(
                command,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,   # Capture stdout!
                text=True
            )
            print("Connector started")

    def ctn_send_to_connector(self, idf: int, command: str, timeout: int, command_log="/tmp/connector.commands.log"):
        now = int(time.time())

        # Log to console
        print(f"[Connector] Sending command (id={idf}, timeout={timeout}): {command}")

        # Log to file
        try:
            with open(command_log, "a") as logf:
                logf.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} id={idf} timeout={timeout} command={command}\n")
        except Exception as e:
            print(f"[Connector] Could not write to command log file: {e}")

        buf = bytearray()
        buf.extend(b"2\0")
        buf.extend(f"{idf}\0".encode('utf-8'))
        buf.extend(f"{timeout}\0".encode('utf-8'))
        buf.extend(f"{now}\0".encode('utf-8'))
        buf.extend(f"{command}\0\0\0\0".encode('utf-8'))

        if self.process and self.process.stdin:
            self.process.stdin.write(buf.decode('utf-8'))
            self.process.stdin.flush()
        else:
            raise RuntimeError("Connector is not running.")

    def ctn_write_next_output_to_file(self, output_file="/tmp/connector.output"):
        """
        Reads the next line from the connector's stdout and appends it to output_file.
        """
        if self.process and self.process.stdout:
            line = self.process.stdout.readline()
            if line:
                with open(output_file, "a") as f:
                    f.write(line)
                return line
        return None

    def ctn_kill_connector(self):
        if self.process:
            self.process.terminate()
            self.process = None
            print("Connector stopped")

def ctn_wait_for_output_file(output_file="/tmp/connector.output", timeout=10, poll_interval=0.2):
    end_time = time.time() + timeout
    while time.time() < end_time:
        if os.path.exists(output_file):
            return True
        time.sleep(poll_interval)
    raise FileNotFoundError(f"Output file {output_file} not found after {timeout} seconds")

def ctn_read_from_output_file(idf: int, output_file="/tmp/connector.output", wait_timeout=10):
    ctn_wait_for_output_file(output_file, wait_timeout)
    with open(output_file, "r") as f:
        lines = f.readlines()
    for line in lines:
        if line.strip().startswith(str(idf)):
            return line.strip().split(" ", 1)[1]
    return None

def ctn_start_connector():
    global connector
    connector = ConnectorLibrary()
    connector.ctn_start_connector()
    return connector

def ctn_kill_connector():
    global connector
    if connector:
        connector.ctn_kill_connector()
        connector = None
    else:
        print("No connector to stop.")

def ctn_send_to_connector(idf: int, command: str, timeout: int = 5, output_file=None, command_log="/tmp/connector.commands.log"):
    global connector
    if connector:
        connector.ctn_send_to_connector(idf, command, timeout, command_log)
        # Capture the output line after sending command
        output_file = output_file or f"/tmp/connector.output.{idf}"
        line = connector.ctn_write_next_output_to_file(output_file)
        # Copy per-test file to common output
        if output_file != "/tmp/connector.output":
            import shutil
            shutil.copyfile(output_file, "/tmp/connector.output")
        return line  # Return the actual line written!
    else:
        raise RuntimeError("Connector is not running.")


def ctn_wait_for_result(idf: int, timeout: int = 5, poll_interval=0.2):
    end_time = time.time() + timeout
    while time.time() < end_time:
        result = ctn_read_from_output_file(idf)
        if result:
            return result
        time.sleep(poll_interval)
    raise TimeoutError(f"No result found for id {idf} within {timeout} seconds.")

def ctn_clean_connector_output(line):
    if not isinstance(line, str):
        line = str(line)
    line = line.strip()
    print(f"CLEAN DEBUG RAW: {repr(line)}")  # This will show hidden chars
    idx = line.find("OK:")
    if idx != -1:
        cleaned = line[idx:]
    else:
        # Fallback to regex if 'OK:' not found
        cleaned = re.sub(r"^[^\w]*", "", line)
    print(f"CLEANED: {repr(cleaned)}")
    return cleaned

def ctn_extract_result_from_log(tc, log_path="/tmp/connector.log", output_path=None):
    """
    Find the line with 'reporting check result' and the right check id.
    Write the 'output:' content to output_path.
    """
    with open(log_path, 'r') as f:
        for line in f:
            # Pattern: reporting check result #<id> ...
            m = re.search(r'reporting check result #(\d+).*output:(.*)', line)
            if m:
                found_id, output = m.group(1), m.group(2).strip()
                if str(found_id) == str(tc):
                    # Write the output to the file
                    output_path = output_path or f"/tmp/connector.output.{tc}"
                    with open(output_path, 'w') as out:
                        out.write(output + "\n")
                                # Also copy to shared output
                    if output_path != "/tmp/connector.output":
                        import shutil
                        shutil.copyfile(output_path, "/tmp/connector.output")
                    return output
            # If not found, raise or return None
        raise Exception(f"No result found for id {tc} in log {log_path}")

@keyword
def ctn_extract_result_from_log(tc, log_path="/tmp/connector.log", output_path=None):
    """
    Find the line with 'reporting check result' and the right check id.
    Write the 'output:' content to output_path.
    """
    import re
    with open(log_path, 'r') as f:
        for line in f:
            m = re.search(r'reporting check result #(\d+).*output:(.*)', line)
            if m:
                found_id, output = m.group(1), m.group(2).strip()
                if str(found_id) == str(tc):
                    output_path = output_path or f"/tmp/connector.output.{tc}"
                    with open(output_path, 'w') as out:
                        out.write(output + "\n")
                                # Also copy to shared output
                    if output_path != "/tmp/connector.output":
                        import shutil
                        shutil.copyfile(output_path, "/tmp/connector.output")
                    return output
        raise Exception(f"No result found for id {tc} in log {log_path}")
    
@keyword
def ctn_extract_multiline_result_from_log(tc, log_path="/tmp/connector.log", output_path=None, timeout=10):
    """
    Extracts multi-line result for check ID from log, waits up to `timeout` seconds.
    """
    import re
    deadline = time.time() + timeout
    result_lines = []

    while time.time() < deadline:
        with open(log_path, 'r') as f:
            lines = f.readlines()

        result_lines.clear()
        in_result = False

        for line in lines:
            if not in_result:
                m = re.search(r'reporting check result #(\d+).*output:(.*)', line)
                if m and str(m.group(1)) == str(tc):
                    result_lines.append(m.group(2).strip())
                    in_result = True
            else:
                if line.strip().startswith("error:") or re.match(r"^\d+ \[20.*", line):
                    break
                result_lines.append(line.strip())

        if result_lines:
            output_path = output_path or f"/tmp/connector.output.{tc}"
            with open(output_path, 'w') as out:
                out.write('\n'.join(result_lines))
            if output_path != "/tmp/connector.output":
                import shutil
                shutil.copyfile(output_path, "/tmp/connector.output")
            return '\n'.join(result_lines)

        time.sleep(0.2)  # wait before retry

    raise Exception(f"No result found for id {tc} in log {log_path} after {timeout}s")