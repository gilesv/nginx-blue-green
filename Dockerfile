FROM nginx

RUN apt-get update && apt-get install vim -y

WORKDIR /data
COPY ./data .

COPY nginx.conf /etc/nginx/nginx.conf
