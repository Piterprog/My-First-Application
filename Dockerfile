
FROM ubuntu


RUN apt-get update && apt-get install -y nginx


COPY ./Web/pages /var/www/html/
COPY ./Web/styles /var/www/html/styles/


EXPOSE 80


CMD ["nginx", "-g", "daemon off;"]
