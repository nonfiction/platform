# Docker Host

## Steps

### 1. Clone this repository

  ```
  git clone git@github.com:nonfiction/docker-host.git
  ```

### 2. Create network, .env and data
  
  ```
  make init
  ```

### 3. Set hostname/FQDN and update .env

  ```
  sudo hostnamectl set-hostname dev1.example.com
  vi .env
  ```

### 4. Create DNS record pointing to this IP. For example: 

  ```
  A dev1.example.com 
  A *.dev1.example.com
  ```

### 5. Start services

  ```
  make up
  ```
