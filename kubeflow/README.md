## Kubeflow on NKP

### Prerequisites

* Kubernetes cluster created using [Nutanix Kubernetes Platform](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform-v2_15:top-get-started-nkp-t.html).

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

* [kustomize version 5.4.3](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.4.3)

* Setup [Nutanix Object Store](https://portal.nutanix.com/page/documents/details?targetId=Objects-v4_2:top-intro-c.html) which will be used by kubeflow pipelines (This is not required for vanilla kubeflow)

* Connect to the kubernetes cluster by downloading kubeconfig from NKP UI Dashboard

### Installation

#### Kubeflow on NKP

* Configure the object store by replacing the following variables:
    * put object store `accesskey` and `secretkey` in `overlays/pipeline/ntnx/object-store-secrets.env`
    * put `objStoreHost` in `overlays/pipeline/ntnx/pipeline-install-config.env`

* Run the following make command from the root of the github repo

```
make install-nkp-kubeflow
```

#### Vanilla Kubeflow
* Run the following make command from the root of the github repo

```
make install-vanilla-kubeflow
```