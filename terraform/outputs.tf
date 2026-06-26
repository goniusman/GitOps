output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_public_ips" {
  value = aws_instance.k8s_workers[*].public_ip
}

# Automatically write out a complete multi-node cluster inventory for Ansible
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/environments/${var.environment}/hosts.yml"
  content  = <<EOT
---
all:
  hosts:
    k8s_master:
      ansible_host: "${aws_instance.k8s_master.public_ip}"
      ansible_user: "ubuntu"
      ansible_ssh_private_key_file: "~/.ssh/${var.ssh_key_name}.pem"
%{ for idx, worker in aws_instance.k8s_workers ~}
    k8s_worker_${idx + 1}:
      ansible_host: "${worker.public_ip}"
      ansible_user: "ubuntu"
      ansible_ssh_private_key_file: "~/.ssh/${var.ssh_key_name}.pem"
%{ endfor ~}
  children:
    kubernetes_master:
      hosts:
        k8s_master:
    kubernetes_workers:
      hosts:
%{ for idx, worker in aws_instance.k8s_workers ~}
        k8s_worker_${idx + 1}:
%{ endfor ~}
    kubernetes:
      children:
        kubernetes_master:
        kubernetes_workers:
EOT
}