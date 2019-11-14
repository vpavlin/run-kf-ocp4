# TF Job Operator

The main changes made to the TF Job Operator and Dashboard is to replace `ClusterRoles` with `Roles`. The main reason for this is that an ordinary OpenShift user does not have privileges to create roles and role bindings on cluster level.

We walso want to add TF Job Operator to [Open Data Hub](https://opendatahub.io) project which deploys all the components on namespace level, thus we need to limit TF Job Operator to namespace scope as well.

Sadly, TF Job Dashboard needs to list namespaces at the moment, which requires a `ClusterRole`. We are at least limiting that `ClusterRole` to as minimal rights as possible (list/get `namespaces`) and the rest is provided by the new `Role`.

## TF Job Dashboard

There is an OpenShift `Route` added for the dashboard 

```
oc get route tf-job-dashboard
```

You need to use `/tfojbs/ui` path with the route to get to the dashboard UI. You can get full URL by running the following command

```
oc get route tf-job-dashboard -o jsonpath='http://{.spec.host}/tfjobs/ui/{"\n"}'
```

You also need to select the namespace where your TF Job Operator is running.

## Run example

After deploying the processed manifest, run the following command:

```
oc apply -f exmaples/tf-job-example.yaml
```

You should see new pods starting, operator emitting logs about new tf-job and you should see the job in the TF Job Dashboard