FROM php:8.1-fpm

ARG user=test
ARG uid=1000

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    supervisor \
    nginx \
    build-essential \
    openssl

RUN docker-php-ext-install gd pdo pdo_mysql sockets

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

WORKDIR /var/www/html

# If you need to fix ssl
# COPY ./openssl.cnf /etc/ssl/openssl.cnf

COPY composer.json .
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-autoloader

COPY . .

RUN chown -R $uid:$uid /var/www/html

# RUN php artisan key:generate && php artisan migrate

# copy nginx default config
RUN cp ./default.conf /etc/nginx/conf.d/

# copy supervisor configuration
COPY ./supervisord.conf /etc/supervisord.conf

# run supervisor
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
