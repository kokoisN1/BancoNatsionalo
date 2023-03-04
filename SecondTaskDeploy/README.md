# readme for the deploy part of the second task 
# This folder holds:
#  1. a cluster defenition k8s yaml.
#  2. the required kubeconfig file.
#  3. a k8s deployment yaml to be published.
#  4. a jenkinsfile that defines the jenkins job.
#
# this job will start a k8s cluster and deploy a "secondtask" deployment running a contianer 
# with a python app that will expose a http and https port 
# on this port and exposed url will result with the message "Hellow world"
