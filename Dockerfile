FROM apache/hadoop:3.5.0
USER root
COPY config/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
COPY config/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
COPY config/mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml
COPY config/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml
