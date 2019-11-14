# TF Job Operator

The main changes made to the TF Job Operator and Dashboard is to replace `ClusterRoles` with `Roles`. The reason for this is that OpenShift is generally used as a multitenant environment and with the access rights in the `ClusterRoles` we are giving the operator pretty extensive power over all namespaces in the cluster.

That might not seem that problematic at first but it would potentially allow user `A` to deploy pods in user's `B` namespace, which is definitely a very big security issue.

With our changes we are switching TF Job Operator to only watch and operate in a single namespace.

Similar problems apply to TF Job Dashboard, but as that needs to list namespaces, which requires a `ClusterRole` we are at least limiting that `ClusterRole` to as minimal rights as possible and the rest is provided by the new `Role`.