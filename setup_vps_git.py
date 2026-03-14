import paramiko
import sys

def setup_bare_repo():
    server = "103.190.93.248"
    user = "root"
    password = "000624282aZ!"
    
    print(f"Connecting to {server}...")
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(server, 22, user, password)
    
    print("Setting up bare Git repository...")
    commands = [
        "mkdir -p /root/healthcart.git",
        "cd /root/healthcart.git && git init --bare",
        "mkdir -p /root/HealthCart_Live"
    ]
    
    for cmd in commands:
        stdin, stdout, stderr = client.exec_command(cmd)
        stdout.channel.recv_exit_status()
        print(f"Executed: {cmd}")
        
    client.close()
    print("Bare repo created on VPS!")

if __name__ == "__main__":
    setup_bare_repo()
