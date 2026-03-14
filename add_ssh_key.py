import paramiko
import sys

def add_ssh_key():
    server = "103.190.93.248"
    user = "root"
    password = "000624282aZ!"
    
    with open("/Users/mahboobhasan/.ssh/id_ed25519.pub", "r") as f:
        pub_key = f.read().strip()
    
    print(f"Connecting to {server}...")
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(server, 22, user, password)
    
    print("Appending SSH key...")
    cmd = f"mkdir -p /root/.ssh && chmod 700 /root/.ssh && echo '{pub_key}' >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"
    stdin, stdout, stderr = client.exec_command(cmd)
    stdout.channel.recv_exit_status()
    print("SSH Key safely appended!")
    client.close()

if __name__ == "__main__":
    add_ssh_key()
