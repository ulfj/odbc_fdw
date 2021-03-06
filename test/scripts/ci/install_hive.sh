#!/bin/bash

# expected environment variables
#
# HADOOP_HOME
# HADOOP_VERSION
# HIVE_HOME
# HIVE_VERSION

echo -e "Host *\n   StrictHostKeyChecking no" | sudo tee ~/.ssh/config
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
sudo apt-get -y install openjdk-7-jre
wget --quiet --directory-prefix=/opt http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
wget --quiet --directory-prefix=/opt http://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz
tar -xzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt
tar -xzf /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt
sed -i -- 's/export JAVA_HOME=${JAVA_HOME}/export JAVA_HOME=\/usr\/lib\/jvm\/java-7-openjdk-amd64/g' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh
${HADOOP_HOME}/bin/hdfs dfs -mkdir /tmp/warehouse
${HADOOP_HOME}/bin/hdfs dfs -chmod g+w /tmp/warehouse
${HADOOP_HOME}/bin/hdfs dfs -mkdir /tmp/warehouse/fdw_tests
${HADOOP_HOME}/bin/hdfs dfs -chmod g+w /tmp/warehouse/fdw_tests
cp $TRAVIS_BUILD_DIR/test/fixtures/hive_example.csv /tmp/warehouse/fdw_tests
${HADOOP_HOME}/sbin/start-dfs.sh
${HIVE_HOME}/bin/schematool -initSchema -dbType derby
nohup ${HIVE_HOME}/bin/hive --service hiveserver2 &
# Wait for server to start
sleep 10
${HIVE_HOME}/bin/beeline -u jdbc:hive2://localhost:10000 -f $TRAVIS_BUILD_DIR/test/fixtures/hive_fixtures.sql

# Install Hiveserver2 driver
sudo apt-get install libsasl2-modules-gssapi-mit
wget --quiet --directory-prefix=/tmp http://public-repo-1.hortonworks.com/HDP/hive-odbc/2.1.2.1002/debian/hive-odbc-native_2.1.2.1002-2_amd64.deb
sudo dpkg -i /tmp/hive-odbc-native_2.1.2.1002-2_amd64.deb

