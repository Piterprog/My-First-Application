
FROM amazonlinux

RUN apt-get update && apt-get install -y nginx

COPY ./Web/pages /var/www/html/
COPY ./Web/styles /var/www/html/styles/

CMD ["/usr/sbin/httpd","-D","FOREGROUND"]

EXPOSE 80
