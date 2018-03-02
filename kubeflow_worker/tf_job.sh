#!/bin/ash

# proxy kubernetes API
kubectl proxy &
sleep 2

# launch TFJob
kubectl create -f tf_job.yaml --server=http://127.0.0.1:8001

# monitor the TFJob until it finishes
until [ "$( kubectl get jobs --selector job-type=MASTER,tf_job_name=example-job --field-selector status.successful=0 --server=http://127.0.0.1:8001 2>&1)" == "No resources found." ];
do
	sleep 1;
done


# gather the results (just in the logs in this case)
JOB=$( kubectl get jobs --selector job-type=MASTER,tf_job_name=example-job --server=http://127.0.0.1:8001 | awk 'FNR == 2 {print $1}' )
echo $JOB
kubectl logs job/$JOB --server=http://127.0.0.1:8001 2>%1 > /pfs/out/result.txt

# clean up
kubectl delete tfjob example-job --server=http://127.0.0.1:8001
kill %1
