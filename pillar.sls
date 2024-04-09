users:
  kartaca:
    password: "kartaca2024"

hosts:
  {% for j in range(128, 256) %}
  "192.168.168.{{ j }}/32": "kartaca.local"
  {% endfor %}

mysql:
  user_name: "user_name"
  password: "password"
  database: "db"
