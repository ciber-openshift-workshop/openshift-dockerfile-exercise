# Build and deploy a Dockerfile on Openshift
Exercise of building and deploying a simple Dockerfile in Openshift 4.

## Goals
The purpose of this exercise is to learn basics of:
* Build an application from source (a git repo) in Openshift, using the Dockerfile build strategy
* Deploy an application in Openshift
* Perform basic status checks on the build and deployment

## Steps

### Setup

1. Fork this repo into your own git account. Make the fork public (to avoid dealing with Git credentials in Openshift)
1. Clone your fork, e.g:   
`$ git clone git@github.com:svejk-ciber/openshift-dockerfile-example.git`
1. Log in to Openshift as a developer  
   `$ oc login -u developer -p developer` # assuming Katacoda.
1. Create a new project for the application:  
   `$ oc new-project docker-build`
   
### Create Openshift app and observe project status 

1. Create a new app: `oc new-app ...`  
   ```
   $ oc new-app --name sleep  https://github.com/svejk-ciber/openshift-dockerfile-example.git
   ...
   --> Creating resources ...
     imagestream.image.openshift.io "bash" created
     imagestream.image.openshift.io "sleep" created
     buildconfig.build.openshift.io "sleep" created
     deploymentconfig.apps.openshift.io "sleep" created
   --> Success
     Build scheduled, use 'oc logs -f bc/sleep' to track its progress.
     Run 'oc status' to view your app.
   ```  
 
   You can also use the argument `--strategy=docker` to be explicit, but in this case there is no ambiguity, 
   since there are no other source files present than the Dockerfile, so Openshift should not choose a different build strategy than        _Docker_.

1. Check status of the project: `oc status`
   ```shell
   $ oc status
   ...
   dc/sleep deploys istag/sleep:latest <-
     bc/sleep docker builds https://github.com/svejk-ciber/openshift-dockerfile-example.git#solution on istag/bash:5.0.11
     deployment #1 deployed 7 minutes ago - 1 pod
   
   3 infos identified, use 'oc status --suggest' to see details.
   ```
   Should not indicate any problems, apart from missing Kubernetes probes. Folloe the tip about the `--suggest` 
   parameter to verify this.
  
1. Briefly review the resources created by `new-app`: `oc get all` 
   `$ oc get all`  
   What resources did `new-app` create? 

1. Check the build log for errors: `oc logs bc/$APP`
   ```
   $ oc logs bc/sleep
   ...
   Push successful
   ```
   Observe that Openshift runs a Dockerfile build, and adds some metadata to the build image with
   `ENV` and `LABEL`instructions.
1. Wait for the pod to become available: `oc get pods`
   ```
   $ oc get pods -w
   NAME             READY   STATUS      RESTARTS   AGE
   sleep-1-8j65k    1/1     Running     0          12m
   sleep-1-build    0/1     Completed   0          13m
   sleep-1-deploy   0/1     Completed   0          12m
   ```
   The builder and deployer pods are done, and we are left with a single running pod, the one with just a build number and Docker 
   image suffix in the name.
 
1. View the application log: `oc log...`
   ```
   $ oc log sleep-1-8j65k
   ...
   Sleep.
   Sleep.
   Sleep.
   ```

1. Review resources created by Openshift
 1. Look at the BuildConfiguration: `oc describe bc $APP`
    ```
    $ oc describe bc sleep
    Name:           sleep
    Namespace:      docker-build
    Created:        16 minutes ago
    Labels:         app=sleep
    ...   
    Strategy:       Docker
    URL:            https://github.com/svejk-ciber/openshift-dockerfile-example.git
    Ref:            solution
    From Image:     ImageStreamTag bash:5.0.11
    Output to:      ImageStreamTag sleep:latest
    ...
    ``` 
    Note that the build strategy has been set to `Docker`, since the source is an unambigious Dockerfile,
    and that the label `app` has been added with the value of the argument we gave to `oc new-app` previously.
    Also observe that the build configuration input and outputs looks as expected.

 1. Inspect the image stream for the built image: 'oc describe is $APP`  
    ```
    $ oc describe is sleep
    Name:                   sleep
    Namespace:              docker-build
    Created:                14 seconds ago
    Labels:                 app=sleep
    Annotations:            openshift.io/generated-by=OpenShiftNewApp
    Image Repository:       default-route-openshift-image-registry.apps-crc.testing/docker-build/sleep
    Image Lookup:           local=false
    Tags:                   <none>
    ```
    Observe that the built image is located in Openshift's internal registry. 

 1. Inspect the deployment Configuration: `oc describe dc $APP`  
    ``` 
    $ oc describe dc sleep
    Name:           sleep
    Namespace:      docker-build
    Created:        4 minutes ago
    Labels:         app=sleep
    ...
    Replicas:       1
    Triggers:       Config, Image(sleep@latest, auto=true)
    Strategy:       Rolling
    Template:
    Pod Template:
    Labels:       app=sleep
                  deploymentconfig=sleep
    Annotations:  openshift.io/generated-by: OpenShiftNewApp
    Containers:
      sleep:
       Image:              image-registry.openshift-image-registry.svc:5000/docker-   build/sleep@sha256:237b14f609d3ab452f7f45ba149119a5d1c97324757e8b29a0acb55b4bc8752f
    ...
    ```
    Note that the deployment config has a trigger in the image stream we looked at before. If the image and 
    thus image stream changes, a new deployment is performed. It is possible to use the hash of the Docker 
    image to identify the image version during troubleshooting and rollbacks (since the `latest` tag gets 
    replaced every time we push a new image version to the internal registry)

1. Check the log of the running container  
 `$ oc logs sleep-1...`
 
### Change the application
In this part, we modify the app, rebuild it and observes that Openshift redeploys the changes.

1. Edit the `CMD` instruction in the Dockerfile to display a counter. The result should look similar to this  
   ```
   FROM bash:5.0.11
   
   CMD ["bash", "-c", "while true; do (( i++ )); echo 'Sleep $i.'; sleep 3; done"]
   ```
1. Commit and push the result on your Git fork.

1. Rebuild the app in Openshift
We must start a build manually, in this case, since there are no CI/CD triggers enabled in the BuildConfig.
```
$ oc start-build sleep
build.build.openshift.io/sleep-2 started
```
1. Check the build logs as above
`$ oc logs -f bc/sleep`

1. Verify that a new deployment got triggered by the build
``` 
$ oc status
In project docker-build on server https://openshift:6443

dc/sleep deploys istag/sleep:latest <-
  bc/sleep docker builds https://github.com/svejk-ciber/openshift-dockerfile-example.git#solution on istag/bash:5.0.11
  deployment #2 deployed 4 minutes ago - 1 pod
  deployment #1 deployed 27 minutes ago
...
```

1. Wait for the app pod to be available: `$ oc get pod ...` as above  
 Note that here are now pods of version 1 and 2 of the builds performed. In the end,
 only the newly built image pod of the latest build (2), should be kept running.

1. View the application log again
```
$ oc log sleep-2-2zffm...
...
Sleep 8
Sleep 9
Sleep 10
...
```
1. Inspect the image stream for the output image as above.
Observe that there are now multiple versions of the image in play on the Docker tag `latest`, 
and that the stream currently points to the last built image, by SHA256 hash.


### Cleanup
You can skip this step if you are using an ephemeral environment like [Katacoda](https://www.katacoda.com/openshift/courses/playgrounds/openshift42). But it's probably 
useful to practice it at least once, since it's frequently used to clear out a failed 
deployment.

1. `oc delete all`: Delete most resources created by `oc new-app` from the project:  
 `$ oc delete all -l app=sleep`

1. Verify that resources are gone:  
 `$ oc get all`  
 Should indicate that there are no resources left in the project.

1. `oc delete project`: Delete the project   
 `$ oc delete project docker-build`
