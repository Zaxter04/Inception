FROM debian:bookworm

RUN apt update 
RUN apt install -y mariadb-server mariadb-client 



COPY	conf/50-server.cnf  /etc/mysql/mariadb.conf.d/50-server.cnf
COPY    tools/mariadb.sh /usr/local/bin/init-db.sh

RUN chmod +x /usr/local/bin/init-db.sh

RUN mkdir /run/mysqld

RUN chown mysql:mysql /run/mysqld

ENTRYPOINT ["/usr/local/bin/init-db.sh"]