# Используем базовый образ Ubuntu
FROM ubuntu

# Устанавливаем Nginx
RUN apt-get update && apt-get install -y nginx

# Копируем файлы HTML и CSS
COPY ./web/pages /var/www/html/
COPY ./web/styles /var/www/html/styles/

# Открываем порт 80
EXPOSE 80

# Запускаем Nginx в фоновом режиме
CMD ["nginx", "-g", "daemon off;"]
