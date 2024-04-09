
{% set is_ubuntu = grains['os_family'] == 'Debian' %}
{% set is_centos = grains['os_family'] == 'RedHat' %}

create_kartaca_user:
  user.present:
    - name: kartaca
    - uid: 2024
    - gid: 2024
    - home: /home/krt
    - shell: /bin/bash
    - password_pillar: users:kartaca:password

grant_sudo_access:
  file.append:
    - name: /etc/sudoers
    - text: 'kartaca ALL=(ALL) NOPASSWD: ALL'
    
grant_yum_access:
  file.append:
    - name: /etc/sudoers
    - text: 'kartaca ALL=(ALL) NOPASSWD: /usr/bin/yum'


set_timezone:
  timezone.system:
    - name: Europe/Istanbul

enable_ip_forwarding:
  sysctl.persist:
    - name: net.ipv4.ip_forward
    - value: 1

install_required_packages:
  pkg.installed:
    - names:
      - htop
      - tcptraceroute
      - iputils
      - bind-utils
      - dnsutils
      - sysstat
      - mtr

install_terraform:
  pkgrepo.managed:
    - name: hashicorp
    - humanname: HashiCorp Official Repository
    - baseurl: https://apt.releases.hashicorp.com
    - gpgkey: https://apt.releases.hashicorp.com/gpg
    - clean: True

  pkg.installed:
    - name: terraform
    - version: 1.6.4

add_host_entries:
  file.append:
    - name: /etc/hosts
    - text_pillar: hosts

{% if is_centos %}
install_nginx:
  pkg.installed:
    - name: nginx

enable_nginx_service:
  service.running:
    - name: nginx
    - enable: True

install_php_packages:
  pkg.installed:
    - names:
      - php
      - php-fpm
      - php-mysql

download_wordpress:
  cmd.run:
    - name: wget -P /tmp https://wordpress.org/latest.tar.gz

extract_wordpress:
  cmd.run:
    - name: tar -xzf /tmp/latest.tar.gz -C /var/www/
    - creates: /var/www/wordpress2024

reload_nginx_on_conf_change:
  cmd.wait:
    - name: systemctl reload nginx
    - watch:
      - file: /etc/nginx/nginx.conf

restart_nginx_monthly:
  cron.present:
    - name: restart_nginx
    - user: root
    - day: 1
    - hour: 0
    - minute: 0
    - job: systemctl restart nginx

nginx_logrotate:
  file.managed:
    - name: /etc/logrotate.d/nginx
    - source: salt://files/nginx.logrotate
    - contents: |
        /var/log/nginx/*.log{
          hourly
          rotate 10
          compress}
    - user: root
    - group: root
    - mode: 644

{% elif is_ubuntu %}
install_mysql:
  pkg.installed:
    - name: mysql-server

enable_mysql_service:
  service.running:
    - name: mysql
    - enable: True

create_wordpress_db_user:
  mysql_user.present:
    - name: {{ pillar['mysql']['user_name'] }}
    - host: localhost
    - password: {{ pillar['mysql']['password'] }}
    - priv: '*.*:ALL'

  mysql_database.present:
    - name: {{ pillar['mysql']['database'] }}
    - owner: {{ pillar['mysql']['user_name'] }}

mysql_backup_cron:
  cron.present:
    - name: mysql_backup
    - user: root
    - hour: 2
    - minute: 0
    - job: /usr/bin/mysqlback -u root --password=<root_password> <database_name> > /backup/database_backup.sql

{% endif %}
