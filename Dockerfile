FROM ubuntu:latest


RUN apt-get update && apt-get install -y tzdata

RUN apt-get update && apt-get install -y nginx 

RUN ln -fs /usr/share/zoneinfo/Asia/Jerusalem /etc/localtime

COPY ./Web/pages /var/www/html/
COPY ./Web/styles /var/www/html/styles/

CMD ["nginx", "-g", "daemon off;"]

EXPOSE 80

