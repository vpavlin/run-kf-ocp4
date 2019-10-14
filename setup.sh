#!/usr/bin/bash

mkdir -p ~/bin
pushd ~/bin
ks -h &> /dev/null
if [ $? -gt 0 ]; then
    echo "==> Install KSonnet"
    wget https://github.com/ksonnet/ksonnet/releases/download/v0.13.1/ks_0.13.1_linux_amd64.tar.gz
    tar -xzf ks_0.13.1_linux_amd64.tar.gz
    ln -s ks_0.13.1_linux_amd64/ks ks
fi

kfctl -h &> /dev/null
if [ $? -gt 0 ]; then
    echo "==> Install kfctl"

    wget https://github.com/kubeflow/kubeflow/releases/download/v0.5.1/kfctl_v0.5.1_linux.tar.gz
    tar -xzf kfctl_v0.5.1_linux.tar.gz
fi
popd

oc new-project kubeflow
oc project kubeflow

export KFAPP=kubeflow
kfctl init ${KFAPP}
cd ${KFAPP}
kfctl generate all -V

echo "==> Configure anyuid SCCs"
oc adm policy add-scc-to-user anyuid -z ambassador
oc adm policy add-scc-to-user anyuid -z default
oc adm policy add-scc-to-user anyuid -z katib-ui
oc adm policy add-scc-to-user anyuid -z jupyter-notebook

echo "==> Deploy KF"
kfctl apply all -V

echo "==> Patch notebook-controller clusterrole see: https://github.com/kubeflow/kubeflow/issues/3861"
oc patch clusterrole notebooks-controller --type='json' -p='[{"op": "add", "path": "/rules/2/resources/2", "value": "notebooks/finalizers"}]'

echo "==> Expose Ambassador"
oc expose service ambassador

echo "==> Update Argo and switch executor to k8sapi"
# 'argoproj/workflow-controller:v2.3.0'
oc patch deployment workflow-controller --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "argoproj/workflow-controller:v2.3.0"}]'
cat << EOF | oc apply -f -
kind: ConfigMap
apiVersion: v1
metadata:
  name: workflow-controller-configmap
  labels:
    app.kubernetes.io/deploy-manager: ksonnet
    ksonnet.io/component: argo
  annotations:
    ksonnet.io/managed: >-
      {"pristine":"H4sIAAAAAAAA/6xSwW6rMBC8v6+w9gyEl57qa09VValqpZ64OM4SbQ27lm2SIMS/Vw6JQu5dcRhphpkRwwTG0zeGSMKg4fgfCtibZEBPYIVbOoCGqWE8ox2ShNfeHFArEw7ig/xsMsicPm6rbVUXDZuQqDU2faKXSEnCqBueGlZKqfik1RXm2w3WYdKq7zx57IixuJMOx4+ALZ1z2mIZVzTy3gtxfpuYpIwYjmSxcsMO205O+rmu65WeOKIdAmqVwrDOMdZijG84fqENuc2qYD42Pa4rlkverVPxqHY46qulw/HOzStdvAT9aeJi+Zi4wLnh5YG5AEe8Bw0vl2HfjYcCekzmNnhndtjFjFwUZkwVycZK74WRE2jIa2ef3BA0nCS4/K1LK5yCdB2Gcvlp+ot3lkVvbNbedoF5/vcLAAD//wEAAP//xq0AG3UCAAA="}
    kubecfg.ksonnet.io/garbage-collect-tag: gc-tag
data:
  config: |
    executorImage: "argoproj/argoexec:v2.3.0"
    ContainerRuntimeExecutor: k8sapi
    artifactRepository:
        s3:
            bucket: "mlpipeline"
            keyPrefix: "artifacts"
            endpoint: "minio-service.kubeflow:9000"
            insecure: true
            accessKeySecret:
                name: "mlpipeline-minio-artifact"
                key: "accesskey"
            secretKeySecret:
                name: "mlpipeline-minio-artifact"
                key: "secretkey"
EOF