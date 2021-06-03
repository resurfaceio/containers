FROM adoptopenjdk/openjdk11:jdk-11.0.10_9-alpine-slim

# Download and configure packages
# Do as one big step to reduce container size!
RUN apk add --no-cache --upgrade wget supervisor python3 less libcrypto1.1 libssl1.1 lighttpd musl musl-utils &&\
mkdir /var/log/supervisord && mkdir /etc/supervisord &&\
wget --quiet https://repo1.maven.org/maven2/io/trino/trino-server/358/trino-server-358.tar.gz &&\
mkdir -p /opt &&\
tar -xf trino-server-358.tar.gz -C /opt &&\
mv /opt/trino-server-358 /opt/trino &&\
rm trino-server-358.tar.gz &&\
sed -i 's|#!/usr/bin/env python|#!/usr/bin/env python3|' /opt/trino/bin/launcher.py &&\
rm -rf /opt/trino/plugin/accumulo &&\
rm -rf /opt/trino/plugin/atop &&\
rm -rf /opt/trino/plugin/bigquery &&\
rm -rf /opt/trino/plugin/blackhole &&\
rm -rf /opt/trino/plugin/cassandra &&\
rm -rf /opt/trino/plugin/clickhouse &&\
rm -rf /opt/trino/plugin/druid &&\
rm -rf /opt/trino/plugin/elasticsearch &&\
rm -rf /opt/trino/plugin/example-http &&\
rm -rf /opt/trino/plugin/geospatial &&\
rm -rf /opt/trino/plugin/google-sheets &&\
rm -rf /opt/trino/plugin/hive-hadoop2 &&\
rm -rf /opt/trino/plugin/iceberg &&\
rm -rf /opt/trino/plugin/jmx &&\
rm -rf /opt/trino/plugin/kafka &&\
rm -rf /opt/trino/plugin/kinesis &&\
rm -rf /opt/trino/plugin/kudu &&\
rm -rf /opt/trino/plugin/local-file &&\
rm -rf /opt/trino/plugin/memsql &&\
rm -rf /opt/trino/plugin/ml &&\
rm -rf /opt/trino/plugin/mongodb &&\
rm -rf /opt/trino/plugin/mysql &&\
rm -rf /opt/trino/plugin/oracle &&\
rm -rf /opt/trino/plugin/phoenix &&\
rm -rf /opt/trino/plugin/phoenix5 &&\
rm -rf /opt/trino/plugin/pinot &&\
rm -rf /opt/trino/plugin/postgresql &&\
rm -rf /opt/trino/plugin/prometheus &&\
rm -rf /opt/trino/plugin/raptor-legacy &&\
rm -rf /opt/trino/plugin/redis &&\
rm -rf /opt/trino/plugin/redshift &&\
rm -rf /opt/trino/plugin/sqlserver &&\
rm -rf /opt/trino/plugin/teradata-functions &&\
rm -rf /opt/trino/plugin/thrift &&\
rm -rf /opt/trino/plugin/tpcds &&\
rm -rf /opt/trino/plugin/tpch
