FROM ubuntu:22.04-slim

RUN apt-get update && \
    apt-get install -y \
      curl \
      php8.1-fpm \
      php8.1-cli \
      php8.1-mysql \
      php8.1-mbstring \
      php8.1-xml \
      php8.1-json \
      php8.1-tokenizer \
      php8.1-pdo \
      php8.1-imagick

WORKDIR /var/www/html

COPY . .

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install

EXPOSE 80
