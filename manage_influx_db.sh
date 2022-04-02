#!/bin/bash

#    /$$$$$$$$ /$$$$$$$   /$$$$$$  /$$$$$$$        /$$$$$$$$ /$$$$$$   /$$$$$$  /$$         #
#   |__  $$__/| $$__  $$ /$$__  $$| $$__  $$      |__  $$__//$$__  $$ /$$__  $$| $$         #
#      | $$   | $$  \ $$| $$  \ $$| $$  \ $$         | $$  | $$  \ $$| $$  \ $$| $$         #
#      | $$   | $$$$$$$/| $$$$$$$$| $$$$$$$/         | $$  | $$  | $$| $$  | $$| $$         #
#      | $$   | $$__  $$| $$__  $$| $$____/          | $$  | $$  | $$| $$  | $$| $$         #
#      | $$   | $$  \ $$| $$  | $$| $$               | $$  | $$  | $$| $$  | $$| $$         #
#      | $$   | $$  | $$| $$  | $$| $$               | $$  |  $$$$$$/|  $$$$$$/| $$$$$$$$   #
#      |__/   |__/  |__/|__/  |__/|__/               |__/   \______/  \______/ |________/   #

### TRAP debug tool designed for IoT project course [Prof. Brunelli Davide,               ###
### Prof. Fontanelli Davide, PhD. Alessandro Torrisi] and                                 ###
### designed by Matteo Spadetto [214352]                                                  ###
### This sys is intended as a dbg tool for the TRAP research of Embedded sys lab in UniTn ###
###                                                                                       ###
### This Linux based bash script manages all the application functions, check -h (help)   ###
### flag for details on what is able to do and how to do it                               ###

show_help() {
    echo "
        Usage: ./manage_influx_db.sh [-d <database>] [-r run <uart_devices>] [-s <meas_to_show>] [-k <meas_to_drop>] [-m] [-f] [-p] [-c] [-w <database>] [-h]

        -d set the database             Set the database on which perform actions
        -r run all <uart_devices>       Running all TRAP tool applicaton passing uart devices
        -s show meas <meas_to_show>     Performing 'select * from <meas_to_show>' InfluxDB command
        -k drop meas <meas_to_drop>     Performing 'DROP MEASUREMENT <meas_to_drop>' InfluxDB command
        -m show all measurements        Performing 'SHOW MEASUREMENTS' InfluxDB command
        -f show all databases           Performing 'SHOW DATABASES' InfluxDB command
        -p drop database and show       Performing 'DROP DATABASE iot_tool' and show InfluxDB command
        -c create database and show     Performing 'CREATE DATABASE iot_tool' and show InfluxDB command
        -w write data in csv file       Generating the csv files of all measurements from specified database

        -h                              Help

        For Example:    ./manage_influx_db.sh -d iot_tool -s rx_done
            OR          ./manage_influx_db.sh -r '/dev/ttyACM3 /dev/ttyACM4'
            OR          ./manage_influx_db.sh -d iot_tool -k tx_done
            OR          ./manage_influx_db.sh -d iot_tool -m 
            OR          ./manage_influx_db.sh -f
            OR          ./manage_influx_db.sh -d iot_tool -p 
            OR          ./manage_influx_db.sh -d iot_tool -c
            OR          ./manage_influx_db.sh -w /path/to/folder/
"
    exit
}

create_database() {
    echo "[InfluxDB] CREATE $1 database";
    influx -database ''" $1 "'''' -execute 'CREATE DATABASE'" $1 "''''
    echo "[InfluxDB] $1 SUCCESFULLY CREATED"
}

drop_database() {
    echo "[InfluxDB] DROPPING $1 database";
    influx -execute 'DROP DATABASE'" $1 "''''
    echo "[InfluxDB] $1 SUCCESFULLY DROPPED"
}

show_databases() {
    echo "[InfluxDB] SHOW databases";
    influx -execute 'SHOW DATABASES'
    echo "[InfluxDB] databases SUCCESFULLY SHOWN"
}


drop_meas() {
    echo "[InfluxDB] DROPPING measurement $1 in iot_tool";
    influx -database "$database" -execute 'DROP MEASUREMENT'" $1 "''''
    influx -database "$database" -execute 'SHOW MEASUREMENTS'
    echo "[InfluxDB] $1 SUCCESFULLY DROPPED"
}

show_meas() {
    echo "[InfluxDB] SHOWING all measurements of iot_tool";
    influx -database "$database" -execute 'SHOW MEASUREMENTS'
    echo "[InfluxDB] measurements SUCCESFULLY SHOWN"
}

show_data(){
    echo "[InfluxDB] SHOWING $1 measurement";
    influx -database "$database" -execute 'select * from'" $1 "''''
    echo "[InfluxDB] $1 measurement SUCCESFULLY SHOWN";
}

write_csv(){
    mkdir $1
    echo "[InfluxDB] Generating engy.csv from engy";
    influx -database 'iot_tool' -execute 'SELECT * FROM engy' -format csv > $1engy.csv
    echo "[InfluxDB] Generating tx_done.csv from tx_done";
    influx -database 'iot_tool' -execute 'SELECT * FROM tx_done' -format csv > $1tx_done.csv
    echo "[InfluxDB] Generating rx_done.csv from rx_done";
    influx -database 'iot_tool' -execute 'SELECT * FROM rx_done' -format csv > $1rx_done.csv
    echo "[InfluxDB] Generating tx_wait.csv from tx_wait";
    influx -database 'iot_tool' -execute 'SELECT * FROM tx_wait' -format csv > $1tx_wait.csv
    echo "[InfluxDB] Generating rx_fail.csv from rx_fail";
    influx -database 'iot_tool' -execute 'SELECT * FROM rx_fail' -format csv > $1rx_fail.csv
    echo "[InfluxDB] Generating burst.csv from burst";
    influx -database 'iot_tool' -execute 'SELECT * FROM burst' -format csv > $1burst.csv
    echo "[InfluxDB] Generating dbg.csv from dbg";
    influx -database 'iot_tool' -execute 'SELECT * FROM dbg' -format csv > $1dbg.csv
    echo "[InfluxDB] All CSV files succesfully generated in $1";
}

run(){
    echo "[Grafana] Stopping Grafana server session"
    sudo systemctl stop grafana-server
    echo "[Linux] Generating required nodes: $uart"
    /usr/bin/python3 constructor.py $uart
    echo "[Grafana] Starting Grafana server session"
    sudo systemctl start grafana-server
    echo "[Node_RED] Running custom 'use_node.json'"
    node-red use_node.json
}

while getopts d:s:k:cpw:r:pmfch flag; do
    case "${flag}" in
    h) show_help
        ;;
    d) database=${OPTARG}
        ;;
    r) uart=${OPTARG}
        run
        ;;
    s) data=${OPTARG}
        show_data "$data"
        exit
        ;;
    k) measd=${OPTARG}
        drop_meas "$measd" 
        exit
        ;;
    m) show_meas
        exit
        ;;
    f) show_databases
        exit
        ;;
    p) drop_database "$database"
        show_databases
        exit
        ;;
    c) create_database "$database"
        show_databases
        exit
        ;;
    w) csv_folder=${OPTARG}
        write_csv "$csv_folder"
        exit
        ;;  
    \?)
        echo "
    Error on command and the problem can be:

        - Invalid option
        - Not correct arguments
        - Too few arguments

    Use -h flag for help
            "
        exit
        ;;
    esac
done

exit
