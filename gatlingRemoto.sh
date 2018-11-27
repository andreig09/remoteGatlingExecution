#!/bin/bash
##################################################################################################################
#Gatling scale out/cluster run script:
#Before running this script some assumptions are made:
#1) Public keys were exchange inorder to ssh with no password promot (ssh-copy-id on all remotes)
#2) Check  read/write permissions on all folders declared in this script.
#3) Gatling installation (GATLING_HOME variable) is the same on all hosts
#4) Assuming all hosts has the same user name (if not change in script)
##################################################################################################################
 
#Remote hosts list with the user to load through ssh
#Change <username> and <IPLoadGenerator> for the user and ip of the load generators
HOSTS=( <username1>@<IPLoadGenerator1> <usermane2>@<IPLoadGenerator2> )
 
#Assuming all Gatling installation in same path (with write permissions)
GATLING_HOME=/usr/local/share/gatling/gatling-charts-highcharts-bundle-3.0.1.1
GATLING_SIMULATIONS_DIR=$GATLING_HOME/user-files/simulations
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh
 
#Change to your simulation class name
SIMULATION_NAME='computerdatabase.BasicSimulation'
 
#No need to change this
GATLING_REPORT_DIR=$GATLING_HOME/results/
GATHER_REPORTS_DIR=/usr/local/share/gatling/reports/
 
echo "Starting Gatling cluster run for simulation: $SIMULATION_NAME"
 
echo "Cleaning previous runs from localhost"
rm -rf $GATHER_REPORTS_DIR
mkdir $GATHER_REPORTS_DIR
rm -rf $GATLING_REPORT_DIR
mkdir $GATLING_REPORT_DIR
 
for HOST in "${HOSTS[@]}"
do
  echo "Cleaning previous runs from host: $HOST"
  ssh -n -f $HOST "sh -c 'sudo rm -rf $GATLING_REPORT_DIR'"
  ssh -n -f $HOST "sh -c 'sudo mkdir -m 777 $GATLING_REPORT_DIR'" #This folder should have write and read permissions for the defined user (no need to be -m 777)
done
 
for HOST in "${HOSTS[@]}"
do
  echo "Copying simulations to host: $HOST"
  scp -r $GATLING_SIMULATIONS_DIR/* $HOST:$GATLING_SIMULATIONS_DIR
done
 
for HOST in "${HOSTS[@]}"
do
  echo "Running simulation on host: $HOST"
  ssh -n -f $HOST "sh -c 'nohup $GATLING_RUNNER -nr -s $SIMULATION_NAME > $GATLING_HOME/run.log 2>&1 &'"
done
 
echo "Running simulation on localhost"
$GATLING_RUNNER -nr -s $SIMULATION_NAME
 
echo "Gathering result file from localhost"
ls -t $GATLING_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_REPORT_DIR}{} ${GATLING_REPORT_DIR}report
cp ${GATLING_REPORT_DIR}report/simulation.log $GATHER_REPORTS_DIR
 
 #Sometimes the execution in remote hosts takes longer time than in local host, 
 # in those cases it should be added a sleep here.
 #sleep 30s
 
for HOST in "${HOSTS[@]}"
do
  echo "Gathering result file from host: $HOST"
  #IMPORTANT: ensure you only have the results folder in ${GATLING_REPORT_DIR} before executing next line, in other case it could fail as it changes other folder/file to "report" folder.
  ssh -n -f $HOST "sh -c 'ls -t $GATLING_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_REPORT_DIR}{} ${GATLING_REPORT_DIR}report'"
  scp $HOST:${GATLING_REPORT_DIR}report/simulation.log ${GATHER_REPORTS_DIR}simulation-$HOST.log
done
 
mv $GATHER_REPORTS_DIR $GATLING_REPORT_DIR
echo "Aggregating simulations"
$GATLING_RUNNER -ro reports
 
#using macOSX
open ${GATLING_REPORT_DIR}reports/index.html
 
#using ubuntu
#google-chrome ${GATLING_REPORT_DIR}reports/index.html