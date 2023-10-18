#!/bin/bash

# Variables
MASTER_NAME="master"
SLAVE_NAME="slave"
PASSWORD="adeben11"

# Initialize Vagrant project
mkdir lamp_vm_cluster
cd lamp_vm_cluster
vagrant init

# Create Vagrantfile for the master VM
cat <<EOL > Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.define "$MASTER_NAME" do |node|
    node.vm.box = "ubuntu/focal64"
    node.vm.network "private_network", type: "dhcp"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
    end
    node.vm.hostname = "$MASTER_NAME"
  end

  config.vm.define "$SLAVE_NAME" do |node|
    node.vm.box = "ubuntu/focal64"
    node.vm.network "private_network", type: "dhcp"
    node.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
    end
    node.vm.hostname = "$SLAVE_NAME"
  end
end
EOL

# Start and provision VMs
vagrant up

# Create user 'altschool' and grant sudo privileges on master
vagrant ssh $MASTER_NAME -c "sudo useradd -m altschool"
vagrant ssh $MASTER_NAME -c "echo 'altschool:$PASSWORD' | sudo chpasswd"
vagrant ssh $MASTER_NAME -c "sudo usermod -aG sudo altschool"

# Set up SSH key-based authentication from master to slave
vagrant ssh $MASTER_NAME -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
vagrant ssh $SLAVE_NAME -c "sudo useradd -m altschool"
vagrant ssh $SLAVE_NAME -c "sudo mkdir -p /home/altschool/.ssh"
vagrant ssh $SLAVE_NAME -c "sudo chown altschool:altschool /home/altschool/.ssh"
vagrant ssh $SLAVE_NAME -c "sudo chmod 700 /home/altschool/.ssh"
vagrant ssh $SLAVE_NAME -c "sudo touch /home/altschool/.ssh/authorized_keys"
vagrant ssh $SLAVE_NAME -c "sudo chown altschool:altschool /home/altschool/.ssh/authorized_keys"
vagrant ssh $SLAVE_NAME -c "sudo chmod 600 /home/altschool/.ssh/authorized_keys"
vagrant ssh $MASTER_NAME -c "cat ~/.ssh/id_rsa.pub" | vagrant ssh $SLAVE_NAME -c "sudo tee -a /home/altschool/.ssh/authorized_keys"

# Copy contents from /mnt/altschool on master to /mnt/altschool/slave on slave
vagrant ssh $MASTER_NAME -c "sudo -u altschool scp -r /mnt/altschool altschool@$SLAVE_NAME:/mnt/altschool/slave"

# Install and configure LAMP stack on both VMs
vagrant ssh $MASTER_NAME -c "sudo apt update"
vagrant ssh $MASTER_NAME -c "sudo apt install -y apache2 mysql-server php libapache2-mod-php"
vagrant ssh $MASTER_NAME -c "sudo systemctl enable apache2"
vagrant ssh $SLAVE_NAME -c "sudo apt update"
vagrant ssh $SLAVE_NAME -c "sudo apt install -y apache2"
vagrant ssh $MASTER_NAME -c "sudo echo 'CREATE USER "altschool" IDENTIFIED BY "$PASSWORD";'" | sudo mysql -u root -p"$PASSWORD"
vagrant ssh $MASTER_NAME -c "sudo echo 'GRANT ALL PRIVILEGES ON *.* TO "altschool" WITH GRANT OPTION;'" | sudo mysql -u root -p"$PASSWORD"

# Test PHP functionality with Apache
vagrant ssh $MASTER_NAME -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php"
vagrant ssh $SLAVE_NAME -c "echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php"

# Output IP addresses for the VMs
echo "Master VM IP Address:"
vagrant ssh $MASTER_NAME -c "hostname -I | cut -d' ' -f1"
echo "Slave VM IP Address:"
vagrant ssh $SLAVE_NAME -c "hostname -I | cut -d' ' -f1"
