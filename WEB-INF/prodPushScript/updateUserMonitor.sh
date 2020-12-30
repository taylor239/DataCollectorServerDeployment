#!/bin/bash

cd ./DataCollectorServerDeployment/
git pull origin master

cp -au ./* /var/lib/tomcat8/DataCollectorServer/
