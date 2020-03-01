# openshift-dockerfile-exercise
Exercise in building and deploying from a simple Dockerfile in Openshift 4.

## Goals
The purpose of this exercise is to learn basics of:
* Build an application from source (a git repo) in Openshift, using the Dockerfile build strategy
* Deploy an application in Openshift
* Perform basic status checks on the build and dployment

## How to build and run
1. Fork this repo into your own git account. Make the fork public (to avoid dealing with Git credentials in Openshift)
1. Clone your fork, e.g: `$ git clone git@github.com:svejk-ciber/openshift-dockerfile-example.git`
1. Log in to Openshift
   `$ oc login -u developer -p developer` # assuming Katacoda.
1. Create a new project for the application:
   `$ oc new-project docker-build`
1. `$ oc new-app --name sleep  https://github.com/svejk-ciber/openshift-dockerfile-example.git`
   You can also use the argument `--strategy=docker` to be explicit, but in this case there is no ambguity, 
   since there are no other source files present than the Dockerfile, so Openshift should not choose a different build strategy than _Docker_.
1. `$ oc status`
  Should not indicate any problems, apart from missing Kubernetes probes.
1. Check the build log for errors:
  ```$ oc logs bc/sleep
  ...
  Push successful
  ```
2. Wait for the pod to become running:
  `$ oc get pods -w`
3. Check the log of the running container:
  `$ oc logs sleep-1...`
4. Observe that `new-app` has created the following resources: one build configuration, one deployemnt configuration
one replication controller, one build and two image streams (oc get bc|dc|is|rc|build|pod...)

