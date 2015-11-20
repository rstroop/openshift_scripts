#! /bin/bash

REMOTE_HOST=REQUIRED

SSH_ARGS="-q -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

#Make sure we have permission to copy everything
oc login -u system:admin
ssh $SSH_ARGS $REMOTE_HOST "oc login -u system:admin"

PROJECTS=($(oc get projects |  awk '{print $1}' | grep -v NAME | grep -v default))

for PROJECT in $PROJECTS; do
    ssh $SSH_ARGS $REMOTE_HOST "oc new-project $PROJECT"

    #Persistent Volumes must be set up manually and will not be synced
    #Create Persistent Volume Claims by brute force, we cannot check for them since they could bind anywhere
    oc get pvc -n $PROJECT -o json > local.json
    scp $SSH_ARGS local.json $REMOTE_HOST:~/local.json
    ssh $SSH_ARGS $REMOTE_HOST "oc create -f local.json" 2>/dev/null
    CLAIMS=($(oc get pvc -n $PROJECT | awk '{print $1}' | grep -v NAME))

    #Clean up persistent volume claims
    REMOTE_CLAIMS=($(ssh $SSH_ARGS $REMOTE_HOST "oc get pvc -n $PROJECT | awk '{print \$1}' | grep -v NAME"))
    INDEX=0
    while (( "$INDEX" < "${#REMOTE_CLAIMS[@]}" )); do
        if [ "${REMOTE_CLAIMS[$INDEX]}" != "${CLAIMS[$INDEX]}" ]; then
            echo "Removing claim ${REMOTE_CLAIMS[$INDEX]}"
            ssh $SSH_ARGS $REMOTE_HOST "oc delete pvc ${REMOTE_CLAIMS[$INDEX]} -n $PROJECT"
            REMOTE_CLAIMS[$INDEX]=''
            REMOTE_CLAIMS=(${REMOTE_PROJECTS[@]})
        else
            ((INDEX++))
        fi
    done

    #Copy services
    SERVICES=($(oc get svc -n $PROJECT | awk '{print $1}' | grep -v NAME))
    for SERVICE in $SERVICES; do
        oc get svc $SERVICE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $REMOTE_HOST "oc get svc $SERVICE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Service $SERVICE in $PROJECT is the SAME"
        else
            echo "Copying service $SERVICE in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $REMOTE_HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $REMOTE_HOST "oc delete se $SERVICE -n $PROJECT"
            fi
            ssh $SSH_ARGS $REMOTE_HOST "oc create -f local.json"
        fi
    done
    
    #Clean up services
    REMOTE_SERVICES=($(ssh $SSH_ARGS $REMOTE_HOST "oc get svc -n $PROJECT | awk '{print \$1}' | grep -v NAME"))
    INDEX=0
    while (( "$INDEX" < "${#REMOTE_SERVICES[@]}" )); do
        if [ "${REMOTE_SERVICES[$INDEX]}" != "${SERVICES[$INDEX]}" ]; then
            echo "Removing service ${REMOTE_SERVICES[$INDEX]}"
            ssh $SSH_ARGS $REMOTE_HOST "oc delete svc ${REMOTE_SERVICES[$INDEX]} -n $PROJECT"
            REMOTE_SERVICES[$INDEX]=''
            REMOTE_SERVICES=(${REMOTE_PROJECTS[@]})
        else
            ((INDEX++))
        fi
    done

    #Copy build configs
    BUILDS=($(oc get bc -n $PROJECT | awk '{print $1}' | grep -v NAME))
    for BUILD in $BUILDS; do
        oc get bc $BUILD -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $REMOTE_HOST "oc get bc $BUILD -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Build $BUILD in $PROJECT is the SAME"
        else
            echo "Copying build $DEPLOYMENT in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $REMOTE_HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $REMOTE_HOST "oc delete bc $BUILD -n $PROJECT"
            fi
            ssh $SSH_ARGS $REMOTE_HOST "oc create -f local.json"
        fi
    done

    #Clean up build configs
    REMOTE_BUILDS=($(ssh $SSH_ARGS $REMOTE_HOST "oc get bc -n $PROJECT | awk '{print \$1}' | grep -v NAME"))
    INDEX=0
    while (( "$INDEX" < "${#REMOTE_BUILDS[@]}" )); do
        if [ "${REMOTE_BUILDS[$INDEX]}" != "${BUILDS[$INDEX]}" ]; then
            echo "Removing build ${REMOTE_BUILDS[$INDEX]}"
            ssh $SSH_ARGS $REMOTE_HOST "oc delete bc ${REMOTE_BUILDS[$INDEX]} -n $PROJECT"
            REMOTE_BUILDS[$INDEX]=''
            REMOTE_BUILDS=(${REMOTE_PROJECTS[@]})
        else
            ((INDEX++))
        fi
    done

    #Copy imagestreams
    IMAGES=($(oc get is -n $PROJECT | awk '{print $1}' | grep -v NAME))
    for IMAGE in $IMAGES; do
        oc get is $IMAGE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' | sed 's/pvd/atl/g' | sed '/dockerRepositoryCheck/d' > local.json
        ssh $SSH_ARGS $REMOTE_HOST "oc get is $IMAGE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        sed -i '/dockerRepositoryCheck/d' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Image $IMAGE in $PROJECT is the SAME"
        else
            echo "Copying image stream $IMAGE in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $REMOTE_HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $REMOTE_HOST "oc delete is $IMAGE -n $PROJECT"
            fi
            ssh $SSH_ARGS $REMOTE_HOST "oc create -f local.json"
            ssh $SSH_ARGS $REMOTE_HOST "oc import-image $IMAGE -n $PROJECT"
            ##Tagging may not be necessary with proper "insecure" annotations
            #TAGS="$(cat local.json | grep "\"tag\":" | awk -F'"' '{print $4}')"
            #for TAG in $TAGS; do
            #    ssh $SSH_ARGS $REMOTE_HOST "oc tag $IMAGE $IMAGE:$TAG -n $PROJECT"
            #done
        fi
    done

    #Clean up image streams
    REMOTE_IMAGES=($(ssh $SSH_ARGS $REMOTE_HOST "oc get is -n $PROJECT | awk '{print \$1}' | grep -v NAME"))
    INDEX=0
    while (( "$INDEX" < "${#REMOTE_IMAGES[@]}" )); do
        if [ "${REMOTE_IMAGES[$INDEX]}" != "${IMAGES[$INDEX]}" ]; then
            echo "Removing image stream ${REMOTE_IMAGES[$INDEX]}"
            ssh $SSH_ARGS $REMOTE_HOST "oc delete is ${REMOTE_IMAGES[$INDEX]} -n $PROJECT"
            REMOTE_IMAGES[$INDEX]=''
            REMOTE_IMAGES=(${REMOTE_PROJECTS[@]})
        else
            ((INDEX++))
        fi
    done

    #Copy external routes
    ROUTES=($(oc get routes -n $PROJECT | awk '{print $1}' | grep -v NAME))
    for ROUTE in $ROUTES; do
        oc get route $ROUTE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $REMOTE_HOST "oc get route $ROUTE -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Route $ROUTE in $PROJECT is the SAME"
        else
            echo "Copying route $ROUTE in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $REMOTE_HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $REMOTE_HOST "oc delete route $ROUTE -n $PROJECT"
            fi
            ssh $SSH_ARGS $REMOTE_HOST "oc create -f local.json"
        fi
    done

    #Clean up routes
    REMOTE_ROUTES=($(ssh $SSH_ARGS $REMOTE_HOST "oc get routes -n $PROJECT | awk '{print \$1}' | grep -v NAME"))
    INDEX=0
    while (( "$INDEX" < "${#REMOTE_ROUTES[@]}" )); do
        if [ "${REMOTE_ROUTES[$INDEX]}" != "${ROUTES[$INDEX]}" ]; then
            echo "Removing route ${REMOTE_ROUTES[$INDEX]}"
            ssh $SSH_ARGS $REMOTE_HOST "oc delete route ${REMOTE_ROUTES[$INDEX]} -n $PROJECT"
            REMOTE_ROUTES[$INDEX]=''
            REMOTE_ROUTES=(${REMOTE_PROJECTS[@]})
        else
            ((INDEX++))
        fi
    done

    #Copy deployment configs
    DEPLOYMENTS=($(oc get dc -n $PROJECT | awk '{print $1}' | grep -v NAME))
    for DEPLOYMENT in $DEPLOYMENTS; do
        oc get dc $DEPLOYMENT -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' | sed '/status/,$d' | sed '$s/,//' > local.json
        ssh $SSH_ARGS $REMOTE_HOST "oc get dc $DEPLOYMENT -n $PROJECT -o json | sed '/selfLink/,/Timestamp/d' " > remote.json
        sed -i '/status/,$d' remote.json
        sed -i '$s/,//' remote.json
        DIFF="$(diff -q local.json remote.json)"
        if [ -z "$DIFF" ]; then
            echo "Deployment $DEPLOYMENT in $PROJECT is the SAME"
        else
            echo "Copying deployment $DEPLOYMENT in $PROJECT"
            echo -e "}" >> local.json
            scp $SSH_ARGS local.json $REMOTE_HOST:~/local.json
            if [ -s remote.json ]; then
                ssh $SSH_ARGS $REMOTE_HOST "oc delete dc $DEPLOYMENT -n $PROJECT"
            fi
            ssh $SSH_ARGS $REMOTE_HOST "oc create -f local.json"
        fi
    done

    #Clean up deployment configs
    REMOTE_DEPLOYMENTS=($(ssh $SSH_ARGS $REMOTE_HOST "oc get dc -n $PROJECT | awk '{print \$1}' | grep -v NAME"))
    INDEX=0
    while (( "$INDEX" < "${#REMOTE_DEPLOYMENTS[@]}" )); do
        if [ "${REMOTE_DEPLOYMENTS[$INDEX]}" != "${DEPLOYMENTS[$INDEX]}" ]; then
            echo "Removing deployment ${REMOTE_DEPLOYMENTS[$INDEX]}"
            ssh $SSH_ARGS $REMOTE_HOST "oc delete dc ${REMOTE_DEPLOYMENTS[$INDEX]} -n $PROJECT"
            REMOTE_DEPLOYMENTS[$INDEX]=''
            REMOTE_DEPLOYMENTS=(${REMOTE_PROJECTS[@]})
        else
            ((INDEX++))
        fi
    done

done

#Clean up projects
REMOTE_PROJECTS=($(ssh $SSH_ARGS $REMOTE_HOST "oc get projects | awk '{print \$1}' | grep -v NAME"))

INDEX=0
while (( "$INDEX" < "${#REMOTE_PROJECTS[@]}" )); do
    if [ "${REMOTE_PROJECTS[$INDEX]}" != "${PROJECTS[$INDEX]}" ]; then
        echo "Removing project ${REMOTE_PROJECTS[$INDEX]}"
        ssh $SSH_ARGS $REMOTE_HOST "oc delete project ${REMOTE_PROJECTS[$INDEX]}"
        REMOTE_PROJECTS[$INDEX]=''
        REMOTE_PROJECTS=(${REMOTE_PROJECTS[@]})
    else
        ((INDEX++))
    fi
done

