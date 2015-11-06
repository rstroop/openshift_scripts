#! /bin/bash

HOST=REDACTED

SSH_ARGS="-q -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

PROJECTS="$(oc get projects |  awk '{print $1}' | grep -v NAME | grep -v default)"

for PROJECT in $PROJECTS; do
    ssh $SSH_ARGS $HOST "oc new-project $PROJECT"

    #Create Persistent Volume Claims
    oc get pvc -n $PROJECT -o json > local.json
    scp $SSH_ARGS local.json $HOST:~/local.json
    ssh $SSH_ARGS $HOST "oc create -f local.json" 2>/dev/null

    SERVICES="$(oc get svc -n $PROJECT | awk '{print $1}' | grep -v NAME)"
    for SERVICE in $SERVICES; do
        oc get svc $SERVICE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $HOST "oc get svc $SERVICE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Service $SERVICE in $PROJECT is the SAME"
        else
            echo "Copying service $SERVICE in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $HOST "oc delete se $SERVICE -n $PROJECT"
            fi
            ssh $SSH_ARGS $HOST "oc create -f local.json"
        fi
    done

    BUILDS="$(oc get bc -n $PROJECT | awk '{print $1}' | grep -v NAME)"
    for BUILD in $BUILDS; do
        oc get bc $BUILD -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $HOST "oc get bc $BUILD -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Build $BUILD in $PROJECT is the SAME"
        else
            echo "Copying build $DEPLOYMENT in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $HOST "oc delete bc $BUILD -n $PROJECT"
            fi
            ssh $SSH_ARGS $HOST "oc create -f local.json"
        fi
    done

    IMAGES="$(oc get is -n $PROJECT | awk '{print $1}' | grep -v NAME)"
    for IMAGE in $IMAGES; do
        oc get is $IMAGE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' | sed 's/pvd/atl/g' | sed '/dockerRepositoryCheck/d' > local.json
        ssh $SSH_ARGS $HOST "oc get is $IMAGE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        sed -i '/dockerRepositoryCheck/d' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Image $IMAGE in $PROJECT is the SAME"
        else
            echo "Copying image $IMAGE in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $HOST "oc delete is $IMAGE -n $PROJECT"
            fi
            ssh $SSH_ARGS $HOST "oc create -f local.json"
            ##Tagging may not be necessary with proper "insecure" annotations
            #TAGS="$(cat local.json | grep "\"tag\":" | awk -F'"' '{print $4}')"
            #for TAG in $TAGS; do
            #    ssh $SSH_ARGS $HOST "oc tag $IMAGE $IMAGE:$TAG -n $PROJECT"
            #done
        fi
    done

    ROUTES="$(oc get routes -n $PROJECT | awk '{print $1}' | grep -v NAME)"
    for ROUTE in $ROUTES; do
        oc get route $ROUTE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $HOST "oc get route $ROUTE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Route $ROUTE in $PROJECT is the SAME"
        else
            echo "Copying route $ROUTE in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $HOST "oc delete route $ROUTE -n $PROJECT"
            fi
            ssh $SSH_ARGS $HOST "oc create -f local.json"
        fi
    done

    DEPLOYMENTS="$(oc get dc -n $PROJECT | awk '{print $1}' | grep -v NAME)"
    for DEPLOYMENT in $DEPLOYMENTS; do
        oc get dc $DEPLOYMENT -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $HOST "oc get dc $DEPLOYMENT -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Deployment $DEPLOYMENT in $PROJECT is the SAME"
        else
            echo "Copying deployment $DEPLOYMENT in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $HOST "oc delete dc $DEPLOYMENT -n $PROJECT"
            fi
            ssh $SSH_ARGS $HOST "oc create -f local.json"
        fi
    done

done
