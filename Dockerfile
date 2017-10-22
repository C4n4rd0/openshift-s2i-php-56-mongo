FROM centos/s2i-base-centos7

# This image provides an Apache+PHP environment for running PHP
# applications.

EXPOSE 8080

ENV PHP_VERSION=5.6 \
    PATH=$PATH:/opt/rh/rh-php56/root/usr/bin

ENV SUMMARY="Platform for building and running PHP $PHP_VERSION applications" \
    DESCRIPTION="PHP $PHP_VERSION available as docker container is a base platform for \
building and running various PHP $PHP_VERSION applications and frameworks. \
PHP is an HTML-embedded scripting language. PHP attempts to make it easy for developers \
to write dynamically generated web pages. PHP also offers built-in database integration \
for several commercial and non-commercial database management systems, so writing \
a database-enabled webpage with PHP is fairly simple. The most common use of PHP coding \
is probably as a replacement for CGI scripts."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Apache 2.4 with PHP 5.6" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,php,php56,rh-php56" \
      name="centos/php-56-centos7" \
      com.redhat.component="rh-php56-docker" \
      version="5.6" \
      release="1" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"


# Install Apache httpd and PHP
#rh-php56-php-pecl-mongo
RUN yum install -y centos-release-scl && \
    INSTALL_PKGS="rh-php56 rh-php56-php rh-php56-php-mysqlnd rh-php56-php-pgsql rh-php56-php-bcmath \
                  rh-php56-php-gd rh-php56-php-intl rh-php56-php-ldap rh-php56-php-mbstring rh-php56-php-pdo \
                  rh-php56-php-pecl-memcache rh-php56-php-process rh-php56-php-soap rh-php56-php-opcache rh-php56-php-xml \
                  rh-php56-php-pecl-xdebug rh-php56-php-gmp rh-php56-php-pear" && \
    yum install -y --setopt=tsflags=nodocs --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Copy extra files to the image.
COPY ./root/ /

# In order to drop the root user, we have to make some directories world
# writeable as OpenShift default security model is to run the container under
# random UID.
RUN sed -i -f /opt/app-root/etc/httpdconf.sed /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf && \
    echo "IncludeOptional /opt/app-root/etc/conf.d/*.conf" >> /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf && \
    sed -i '/php_value session.save_path/d' /opt/rh/httpd24/root/etc/httpd/conf.d/rh-php56-php.conf && \
    head -n151 /opt/rh/httpd24/root/etc/httpd/conf/httpd.conf | tail -n1 | grep "AllowOverride All" || exit && \
    mkdir /tmp/sessions && \
    chown -R 1001:0 /opt/app-root /tmp/sessions && \
    chmod -R a+rwx /tmp/sessions && \
    chmod -R ug+rwx /opt/app-root && \
    chmod -R a+rwx /etc/opt/rh/rh-php56 && \
    chmod -R a+rwx /opt/rh/httpd24/root/var/run/httpd && \
    chmod -R a+rwx /usr/libexec/s2i/assemble
    
#RUN pecl install mongodb \
#    && docker-php-ext-enable mongodb
RUN pecl install mongodb

RUN echo "extension=mongodb.so" | tee /etc/opt/rh/rh-php56/php.ini
    
USER 1001

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usagee
