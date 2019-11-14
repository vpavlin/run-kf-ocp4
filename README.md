# run-kf-ocp4

This repository contains work done to bring Kubeflow closer to running on OpenShift without relaxing OpenShift security. After running the `generate.yml` Ansible playbook you will find tweaked manifests in `manifests/` directory. It does not contain all Kubeflow components, but the list will grow over time.

Look into the [Docs](./docs) directory for more information on the changes made.

## How to generate manifests

```
ansible generate.yml -e namespace=kf-on-openshift
```

The playbook will download `kfctl` and `kustomize` to `./bin` directory to make sure versions are consistent, then it uses `kfctl` to generate all the Kubeflow deployment manifests into `kubeflow` directory and after that it proceeds to manipulate those manifest to follow OpenShift best practices. Resulting manifests for deployment can be found in directory `manifests/`.

We use Kustomize to mangle the Kubeflow manifest to have reproducible and consistent way of generating the manifests. This should also help with providing some of the changes as PRs in Kubeflow project itself

You can deploy the resulting manifests by running

```
oc apply -f manifests/
```

## How to clean up

```
ansible cleanup.yml
```

The above command will remove all the downloaded and generated files in case you need to start from scratch