#!/bin/bash

oc delete dc $1
oc delete bc $1
oc delete svc $1
oc delete is $1
oc get builds | grep $1 | awk '{print $1}' | xargs oc delete build
oc get pods | grep $1 | awk '{print $1}' | xargs oc delete pod
