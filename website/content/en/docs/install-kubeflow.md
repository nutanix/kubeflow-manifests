+++
title = "Install Kubeflow"
description = "How to deploy Kubeflow on a Nutanix Kubernetes Engine(NKE) cluster"
weight = 4
                    
+++

## Prerequisites


* Create [Nutanix Kubernetes Engine Cluster](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Engine-v2_8:top-deploy-kubernetes-cluster-t.html) (Kubernetes Version 1.25)

* Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)

* Install [kustomize version 5.0.3](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.0.3)

* Download [Kubeconfig](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Engine-v2_7:top-download-kubeconfig-t.html) of your deployed NKE cluster. 

## Installing Kubeflow with Nutanix Object Store

1. Clone the kubeflow manifest github repository and checkout release branch of {{% nutanix/latest-version %}} release.

   ```
   git clone -b release-v1.8 https://github.com/nutanix/kubeflow-manifests.git && cd kubeflow-manifests
   ```

2. Setup [Nutanix Object Store](https://portal.nutanix.com/page/documents/details?targetId=Objects-v4_2:top-intro-c.html).

3. Configure the object store in kubeflow manifests:

    * put object store `accesskey` and `secretkey` in `kubeflow/overlays/pipeline/ntnx/object-store-secrets.env`
    * put `objStoreHost` in `kubeflow/overlays/pipeline/ntnx/pipeline-install-config.env`

4. Run the following make command from the root of the github repository.

   ```
   make install-nke-kubeflow
   ```
## Installing Vanilla Kubeflow

1. Clone the kubeflow manifest github repository and checkout release branch of {{% nutanix/latest-version %}} release.

   ```
   git clone -b release-v1.8 https://github.com/nutanix/kubeflow-manifests.git && cd kubeflow-manifests
   ```

2. Run the following make command from the root of the github repository.

   ```
   make install-vanilla-kubeflow
   ```

**Note:** After kubeflow installation, make sure all the pods in following namespaces are running

   ```
   kubectl get pods -n cert-manager
   kubectl get pods -n istio-system
   kubectl get pods -n auth
   kubectl get pods -n knative-eventing
   kubectl get pods -n knative-serving
   kubectl get pods -n kubeflow
   kubectl get pods -n kubeflow-user-example-com
   ```

## Add a new Kubeflow user

New users are created using the Profile resource. A new namespace is created with the same Profile name. For creating a new user with email `user2@example.com` in a namespace `project1`, apply the following profile

   ```
   cat <<EOF | kubectl apply -f -
   apiVersion: kubeflow.org/v1
   kind: Profile
   metadata:
       name: project1   # replace with the name of profile you want, this will be the user's namespace name
   spec:
       owner:
           kind: User
           name: user2@example.com   # replace with the user email
   EOF
   ``` 
    
If you are using basic authentication, add the user credentials in dex which is the default OpenId Connect provider in Kubeflow. Generate the hash by using bcrypt (available at https://bcrypt-generator.com) in the following configmap
 
    
   ```
   kubectl edit cm dex -o yaml -n auth
   ```

Add the following  under staticPasswords section
    
   ```
   - email: user2@example.com
     hash: <hash>
     username: user2
   ```

Rollout restart dex deployment

   ```
   kubectl -n auth rollout restart deployment dex
   ```

## Setup LoadBalancer (Optional)
  If you already have a load balancer set up for your NKE cluster, you can skip this step. If you do not wish to
  expose the kubeflow dashboard to an external load balancer IP, you can also skip this step.
  If not, you can install the [MetalLB](https://metallb.universe.tf/) load balancer manifests on your NKE cluster.
  ```
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.11/config/manifests/metallb-native.yaml
  ```

  After the manifests have been applied, we need to configure MetalLB with the IP range that it can use to assign external IPs to services of type LoadBalancer. You can find the range from the subnet in Prism Central’s [networking and security](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Flow-Networking-Guide:ear-flow-nw-view-subnet-list-pc-r.html) settings.

  * Create `IPAddressPool` custom resource by applying the following manifest to your cluster. Substitute the addresses field with your IP address range.
  ```
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: kf-ip-address-pool
    namespace: metallb-system
  spec:
    addresses:
    - <IP_ADDRESS_RANGE: x.x.x.x-x.x.x.x>
  ```

  * Create `L2Advertisement` custom resource by applying the following manifest to your cluster.
  ```
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    name: kf-l2advertisement
    namespace: metallb-system
  spec:
    ipAddressPools:
    - kf-ip-address-pool
  ```

## Access Kubeflow Central Dashboard
There are multiple ways to acces your Kubeflow Central Dashboard:
- Port Forward: The default way to access Kubeflow Central Dashboard is by using Port-Forward. You can port forward the istio ingress gateway to local port 8080.
    
   ```
   kubectl --kubeconfig=<NKE_k8s_cluster_kubeconfig_path> port-forward svc/istio-ingressgateway -n istio-system 8080:80
   ```
    
  You can now access the Kubeflow Central Dashboard at http://localhost:8080. At the Dex login page, enter user credentials that you previously created.
    
 
- NodePort: For accessing through NodePort, you need to configure HTTPS. Create a certificate using cert-manager for your Worker node IP in your cluster. Add HTTPS to kubeflow gateway as given in [Istio Secure Gateways](https://istio.io/latest/docs/tasks/traffic-management/ingress/secure-ingress/). Then access your cluster at
   
   ```
   https://<worknernode-ip>:<https-nodeport>
   ```
- LoadBalancer: If you have a LoadBalancer set up (See optional "Setup a LoadBalancer" section above), you can access the dashboard using the external IP by making the following changes.
  - Update Istio Gateway to expose port 443 with HTTPS and make port 80 redirect to 443:
    ```
    kubectl -n kubeflow edit gateways.networking.istio.io kubeflow-gateway
    ```
    The updated gateway spec should look like:
    ```yaml
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    metadata:
      name: kubeflow-gateway
      namespace: kubeflow
    spec:
      selector:
        istio: ingressgateway
      servers:
      - hosts:
        - '*'
        port:
          name: http
          number: 80
          protocol: HTTP
        # Upgrade HTTP to HTTPS
        tls:
          httpsRedirect: true
      - hosts:
        - '*'
        port:
          name: https
          number: 443
          protocol: HTTPS
        tls:
          mode: SIMPLE
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
    ```
  - Change the type of the istio-ingressgateway service to LoadBalancer
    ```
    kubectl -n istio-system  patch service istio-ingressgateway -p '{"spec": {"type": "LoadBalancer"}}'
    ```
    Get the IP address for the `LoadBalancer`
    ```
    kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0]}'
    ```
    Create a `certificate.yaml` with the YAML below to create a self-signed certificate
    ```
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: istio-ingressgateway-certs
      namespace: istio-system
    spec:
      commonName: istio-ingressgateway.istio-system.svc
      ipAddresses:
        - <ISTIO_INGRESSGATEWAY_IP_ADDRESS: x.x.x.x>
      isCA: true
      issuerRef:
        kind: ClusterIssuer
        name: kubeflow-self-signing-issuer
      secretName: istio-ingressgateway-certs
    ```
    Apply `certificate.yaml` to the `istio-system` namespace
    ```
    kubectl -n istio-system apply -f certificate.yaml
    ```
  - You can now access the kubeflow dashboard by navigating to the istio-ingressgateway external IP e.g. `x.x.x.x`

