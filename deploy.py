import paramiko
from scp import SCPClient
import sys

def create_ssh_client(server, port, user, password):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(server, port, user, password)
    return client

def deploy():
    server = "103.190.93.248"
    user = "root"
    password = "000624282aZ!"
    
    print(f"Connecting to {server}...")
    ssh = create_ssh_client(server, 22, user, password)
    
    print("Creating directory...")
    stdin, stdout, stderr = ssh.exec_command("mkdir -p /root/HealthCart")
    stdout.channel.recv_exit_status()
    
    print("Uploading deploy.tar.gz...")
    with SCPClient(ssh.get_transport()) as scp:
        scp.put("/Users/mahboobhasan/Desktop/HeathCart/deploy.tar.gz", "/root/HealthCart/")
        
    print("Extracting archive...")
    stdin, stdout, stderr = ssh.exec_command("cd /root/HealthCart && tar -xzf deploy.tar.gz")
    stdout.channel.recv_exit_status()
    
    print("Executing docker-compose pull...")
    stdin, stdout, stderr = ssh.exec_command("cd /root/HealthCart && docker-compose pull")
    for line in stdout:
        print("PULL:", line.strip())
        
    print("Executing docker-compose up -d...")
    stdin, stdout, stderr = ssh.exec_command("cd /root/HealthCart && docker-compose up -d")
    for line in stdout:
        print("UP:", line.strip())
        
    ssh.close()
    print("Deployment triggered successfully!")

if __name__ == "__main__":
    deploy()
