FROM ubuntu:latest

# Обновляем пакеты и устанавливаем nginx
RUN apt-get update && apt-get install -y nginx
RUN yum -y install epel-release && \
    yum -y install php

# Копируем веб-страницы
COPY ./Web/pages /var/www/html/
COPY ./Web/styles /var/www/html/styles/

# Команда для запуска nginx
CMD ["nginx", "-g", "daemon off;"]

# Открываем порт 80
EXPOSE 80

