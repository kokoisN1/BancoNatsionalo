# readme for jenkins job to get an artifact and version from another 
# jenkins server and job
# the artifacts are a exported container (tar.gz format) and a version (txt format).
# the job will push the docker containr to the ECR repository named 591994479995.dkr.ecr.us-east-2.amazonaws.com/secondtask with the correct version.
# the job assumes that the jenkins agent has the aws cli and it is configured.
# the job assumes that the jenkins agent have wget
# the job have 2 URL pramaters that need to be pointed tat the source server URL and the job providing the artifacts. 