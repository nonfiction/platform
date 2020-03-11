# Docker Host

## Steps


### 1. Create Docker Droplet

  <https://cloud.digitalocean.com/marketplace/5ba19751fc53b8179c7a0071>

### 2. Create DNS record pointing to this IP. For example: 

  ```
  A dev1.example.com 
  A *.dev1.example.com
  ```

### 3. Set hostname/FQDN and update .env

  ```
  ssh root@dev1.example.com
  hostnamectl set-hostname dev1.example.com
  vi .env
  ```

### 4. Configure SSH

  <https://github.com/docker/compose/issues/6463>

  ```
  echo "MaxSessions 500" >> /etc/ssh/sshd_config
  service ssh restart
  ```

### 5. Install docker-compose

  <https://docs.docker.com/compose/install/>

  ```
  curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ```

### 6. Clone this repository

  ```
  git clone git@github.com:nonfiction/docker-host.git
  ```

### 7. Create network, .env and data
  
  ```
  make init
  ```


### 5. Start services

  ```
  make up
  ```
