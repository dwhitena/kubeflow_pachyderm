# Pachyderm + Kubeflow Example

This Pachyderm pipeline demonstrates running a [TFJob](https://github.com/kubeflow/tf-operator) via [KubeFlow](https://github.com/kubeflow/kubeflow) as a stage of a [Pachyderm](http://pachyderm.io/) pipeline. The TFJob is the [standard example TFJob](https://github.com/kubeflow/tf-operator/blob/master/examples/tf_job.yaml) given in the KubeFlow repository, which tests TF distributed. It runs unmodified in this pipeline, and the output (which is just logged in the example) is collected and versioned in Pachyderm. 

Regarding KubeFlow/TensorFlow Distributed + Pachyderm, a couple of notes:

- Further integrations are being worked on that will hopefully make this more seamless (see [this issue](https://github.com/kubeflow/kubeflow/issues/151)). However, this is perfectly functional as is and could be used for distributed TensorFlow integration with Pachyderm.

- In the example we are simply collecting the TF logs, which include the job output. In a more realistic example, you would likely need to either (i) utilize a Pachyderm language client in your TensorFlow code to pull in the latest (`master`) input data for processing and then send the output data back to Pachyderm, and/or (ii) utilize an object store bucket as a go-between for transferring data from Pachyderm to the TFJob and then back. Again, work in being done that will hopefully make this part a little easier.

- I have demonstrated triggering of the job with `kubectl` directly, but this could be done in any preferred way of interacting with the Kubernetes API (e.g., the Python client).

## Deploying the pipeline

1. First, deploy KubeFlow as specified [here](https://github.com/kubeflow/kubeflow/blob/master/user_guide.md#deploy-kubeflow).

2. Then deploy Pachyderm on the same cluster as documented [here](http://pachyderm.readthedocs.io/en/latest/getting_started/local_installation.html) (for a local install) or [here](http://pachyderm.readthedocs.io/en/latest/deployment/deploy_intro.html) (for a cloud or on prem cluster).

3. Create an input data repository in Pachyderm for the pipeline. This is a dummy repo in this case, because the sample Job creates it's own input data. However, it illustrates how such a distributed stage would be triggered:

    ```
    $ pachctl create-repo sample_input
    ```

4. Create the Pachyderm pipeline that utilizes distributed TF via a TFJob. 

    ```
    $ pachctl create-pipeline tf_sample_pipeline.json
    ``` 

## Triggering the TFJob from Pachyderm

The TFJob will be created and run whenever there is new data to be processed in the input data repository `sample_input`. Thus, to trigger our distributed TF pipeline, we just need to add some input data:

```
$ pachctl put-file sample_input master blah.txt -c -f data/blah.txt
```

Immediately this will launch a Pachyderm job, which itself launches distributed TF via KubeFlow's TFJob CRD:

```
$ pachctl put-file sample_input master blah.txt -c -f data/blah.txt
$ pachctl list-job
ID                               OUTPUT COMMIT                              STARTED                DURATION RESTART PROGRESS  DL UL STATE
8b94672c567a4aacb8ab777ccb8531e6 tf_sample/4060283219e745399fe495707f445382 Less than a second ago -        0       0 + 0 / 1 0B 0B running
$ kubectl get jobs
NAME                        DESIRED   SUCCESSFUL   AGE
example-job-master-xpjm-0   1         0            0s
example-job-ps-xpjm-0       1         0            0s
example-job-ps-xpjm-1       1         0            0s
example-job-worker-xpjm-0   1         0            0s
```

After the Pachyderm job completes, we can see that output data in the output data repository created by Pachyderm to version the output of the pipeline:

```
$ pachctl list-job
ID                               OUTPUT COMMIT                              STARTED       DURATION       RESTART PROGRESS  DL UL       STATE
8b94672c567a4aacb8ab777ccb8531e6 tf_sample/4060283219e745399fe495707f445382 2 minutes ago About a minute 0       1 + 0 / 1 5B 7.844KiB success
$ pachctl list-repo
NAME                CREATED             SIZE
tf_sample           4 minutes ago       7.844KiB
sample_input        4 minutes ago       5B
$ pachctl list-file tf_sample master
NAME                TYPE                SIZE
result.txt          file                7.844KiB
$ pachctl get-file tf_sample master result.txt
INFO:root:Tensorflow version: 1.3.0-rc2
INFO:root:Tensorflow git version: v1.3.0-rc1-27-g2784b1c
INFO:root:tf_config: {u'environment': u'cloud', u'cluster': {u'worker': [u'example-job-worker-xpjm-0:2222'], u'ps': [u'example-job-ps-xpjm-0:2222', u'example-job-ps-xpjm-1:2222'], u'master': [u'example-job-master-xpjm-0:2222']}, u'task': {u'index': 0, u'type': u'master'}}
INFO:root:task: {u'index': 0, u'type': u'master'}
etc...
etc...
```

## The Pachyderm KubeFlow worker

The Pachyderm KubeFlow worker image that is used in the pipeline utilize [a script](kubeflow_worker/tf_job.sh) to:

1. Launch the TFJob
2. Wait for the TFJob to complete
3. Gather the results
4. Clean up the TFJob

This can be seen in the Pachyderm logs for that jobs:

```
$ pachctl get-logs --job=8b94672c567a4aacb8ab777ccb8531e6
Starting to serve on 127.0.0.1:8001
tfjob "example-job" created
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
waiting for TFJob to finish
tfjob "example-job" deleted
```
