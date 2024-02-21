FROM ubuntu:latest

# Обновляем пакеты и устанавливаем nginx и PHP
RUN apt-get update && apt-get install -y nginx php

# Устанавливаем часовой пояс для Израиля (Tel Aviv)
RUN ln -fs /usr/share/zoneinfo/Asia/Jerusalem /etc/localtime

# Копируем веб-страницы
COPY ./Web/pages /var/www/html/
COPY ./Web/styles /var/www/html/styles/

# Команда для запуска nginx
CMD ["nginx", "-g", "daemon off;"]

# Открываем порт 80
EXPOSE 80
