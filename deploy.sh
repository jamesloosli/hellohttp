#!/bin/bash

function usage() {
    echo "Valid commands are: create, update, canary, destroy"
    echo "For create, update specify version, for canary specify version and matcher"
    echo "Example:"
    echo " \$ $0 create 2.0"
    echo " \$ $0 update 2.0"
    echo " \$ $0 canary 2.0 '000*'"
    echo " \$ $0 destroy"
    echo " \$ $0 destroy-canary"
    echo " \$ $0 "
    exit 1
}

function check_stack() {
    res=$(aws cloudformation describe-stacks --stack-name ${1} 2> /dev/null | jq -r '.Stacks[0].StackStatus')
    if [ -z $res ]; then
        res="DOES_NOT_EXIST"
    fi
    echo $res
}

function wait_for_stack() {
    [ -z $1 ] && usage
    status=$(check_stack ${1})
    if [[ $status == *_COMPLETE ]]; then
        return
    fi
    echo -n "Waiting for completion"
    until [[ "$status" == *_COMPLETE ]]; do
        sleep 10; echo -n '.'
        status=$(check_stack ${1})
    done
    echo
}

case "$1" in
    "create")

        [ -z $2 ] && usage
        # Create VPC, ALB
        status=$(check_stack bluegreendemo-networking)
        if [[ $status == *_COMPLETE ]]; then
            echo "Base Stack Exists, Updating"
            aws cloudformation update-stack \
                --stack-name bluegreendemo-networking \
                --template-body file://`pwd`/cloudformation/networking.yaml \
                --capabilities CAPABILITY_IAM \
                2>/dev/null
            # Wait for creation to be complete
            wait_for_stack bluegreendemo-networking
        elif [ $status == "DOES_NOT_EXIST" ]; then
            echo "Creating Base Stack"
            aws cloudformation create-stack \
                --stack-name bluegreendemo-networking \
                --template-body file://`pwd`/cloudformation/networking.yaml \
                --capabilities CAPABILITY_IAM \
                2>/dev/null
            # Wait for creation to be complete
            wait_for_stack bluegreendemo-networking
        else
            echo "Networking stack in a bad state, exiting."
            exit 1
        fi


        # Create default service

        status=$(check_stack bluegreendemo-defaultservice)
        if [[ $status == *_COMPLETE ]]; then
            echo "Default Service Exists, Updating"
            aws cloudformation update-stack \
                --stack-name bluegreendemo-defaultservice \
                --template-body file://`pwd`/cloudformation/ecs_service.yaml \
                --parameters \
                    ParameterKey=ServiceName,ParameterValue=helloservice \
                    ParameterKey=ImageUrl,ParameterValue=roosri/hellohttp:v${2} \
                    ParameterKey=Priority,ParameterValue=100 \
                    ParameterKey=StackName,ParameterValue=bluegreendemo-networking \
                    2>/dev/null
            wait_for_stack bluegreendemo-defaultservice
        elif [ $status == "DOES_NOT_EXIST" ]; then
            echo "Creating Default Service"
            aws cloudformation create-stack \
                --stack-name bluegreendemo-defaultservice \
                --template-body file://`pwd`/cloudformation/ecs_service.yaml \
                --parameters \
                    ParameterKey=ServiceName,ParameterValue=helloservice \
                    ParameterKey=ImageUrl,ParameterValue=roosri/hellohttp:v${2} \
                    ParameterKey=StackName,ParameterValue=bluegreendemo-networking \
                    2>/dev/null
            wait_for_stack bluegreendemo-defaultservice
        else
            echo "Default Service stack in a bad state, exiting"
            exit 1
        fi

        wait_for_stack bluegreendemo-defaultservice

        ;;

    "canary")
        [ -z $2 ] && usage
        [ -z $3 ] && usage
        aws cloudformation create-stack \
            --stack-name bluegreendemo-canaryservice \
            --template-body file://`pwd`/cloudformation/ecs_service.yaml \
            --parameters \
                ParameterKey=ServiceName,ParameterValue=helloservicecanary \
                ParameterKey=ImageUrl,ParameterValue=roosri/hellohttp:v${2} \
                ParameterKey=StackName,ParameterValue=bluegreendemo-networking \
                ParameterKey=Priority,ParameterValue=200\
                ParameterKey=Path,ParameterValue=${3} \
                2>/dev/null

        wait_for_stack bluegreendemo-canaryservice
        ;;

    "destroy")
        echo "RIP"
        aws cloudformation delete-stack --stack-name bluegreendemo-networking
        aws cloudformation delete-stack --stack-name bluegreendemo-defaultservice
        ;;

    "destroy-canary")
        echo "RIP"
        aws cloudformation delete-stack --stack-name bluegreendemo-canaryservice
        ;;

    "status")
        echo -n "Networking:       "; check_stack bluegreendemo-networking
        echo -n "Initial Service:  "; check_stack bluegreendemo-defaultservice
        echo -n "Canary Service:   "; check_stack bluegreendemo-canaryservice
        ;;

    *)
        echo "Valid commands are: create, update, canary, destroy"
        echo "For create, update specify version, for canary specify version and matcher"
        echo "Example:"
        echo " \$ $0 create 2.0"
        echo " \$ $0 canary 2.0 '000*'"
        echo " \$ $0 destroy"
        echo " \$ $0 destroy-canary"
        echo " \$ $0 status"
        exit 1
        ;;
esac