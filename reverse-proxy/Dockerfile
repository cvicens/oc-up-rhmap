# [START all]
FROM nginx:alpine
#FROM xqdocker/ubuntu-nginx

#RUN apk add --no-cache certbot

RUN mkdir /usr/share/nginx/html/certs
COPY ca/ca.* /usr/share/nginx/html/certs/
COPY nginx.conf /etc/nginx/nginx.conf

# [END all]