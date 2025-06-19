+++
title = "Integrate with Nutanix Storage"
description = "How to integrate Nutanix Storage in Kubeflow"
weight = 5

+++

## Nutanix Objects in Kubeflow Pipeline

You can use standard s3 boto api to upload and download objects from a Kubeflow Pipeline. See [Nutanix Objects Docs](https://portal.nutanix.com/page/documents/details?targetId=Objects-v4_2:Objects-v4_2) for more details on creating object store and buckets.

   ```
   import boto3

   bucket_name="ml-pipeline-storage"
   object_name="models"
   object_store_access_key_id="<key_id>"
   object_store_secret_access_key="<access_key>"
   host="http://<Nutanix Objects Store Domain Name>"
   region_name='us-west-1'
   s3_client = boto3.client(
                    's3',
                    endpoint_url=host,
                    aws_access_key_id=object_store_access_key_id,
                    aws_secret_access_key=object_store_secret_access_key,
                    region_name=region_name,
                    verify=False)
   response = s3_client.upload_file(f'./test_upload_data.txt', bucket_name, object_name)
   ```

## Nutanix Volumes in Kubeflow Pipeline

Nutanix volumes are created with the default storage class configured in the NKP cluster. See [Default Storage Class](https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Kubernetes-Platform-v2_15:top-default-storage-providers-c.html) of Nutanix Kubernetes Platform for more details about creating storage classes. You can refer to this [example](https://github.com/kubeflow/pipelines/blob/da358e5176f83084ffa06ceb180b815064fb15ee/samples/v2/pipeline_with_volume.py) for more details.

   ```
   from kfp import kubernetes

   pvc1 = kubernetes.CreatePVC(
        pvc_name_suffix='-my-pvc',
        access_modes=['ReadWriteOnce'],
        size='1Gi',
   )

   # Given that you have a pipelines task called task1
   kubernetes.mount_pvc(
        task1,
        pvc_name=pvc1.outputs['name'],
        mount_path='/data',
   )
   ```

## Nutanix Files in Kubeflow Pipeline
    
   Create a storage class to dynamically provision Nutanix File shares. See [Files Storage Class](https://portal.nutanix.com/page/documents/details?targetId=CSI-Volume-Driver-v2_3:csi-csi-plugin-manage-dynamic-nfs-t.html) of Nutanix Kubernetes Platform for more details on creating storage classes for dynamic NFS Share provisioning with Nutanix Files.
   Once storage class is setup, you can use `CreatePVC` operation to create a PVC on a Nutanix Files storage class which can be used to mount to tasks using mount_pvc. You can refer to this [example](https://github.com/kubeflow/pipelines/blob/da358e5176f83084ffa06ceb180b815064fb15ee/samples/v2/pipeline_with_volume.py) for more details.
    
   ```
   from kfp import kubernetes

   pvc1 = kubernetes.CreatePVC(
        pvc_name_suffix='-my-pvc',
        access_modes=['ReadWriteMany'],
        size='1Gi',
        storage_class_name='files-sc',
   )

   # Given that you have a pipelines task called task1
   kubernetes.mount_pvc(
        task1,
        pvc_name=pvc1.outputs['name'],
        mount_path='/data',
   )
   ```

## Using Nutanix Objects as an artifact store

In order to use Nutanix Objects as an underlying artifact store, install the kubeflow with Nutanix object store.

![objects_browser](../images/objects_browser.png)

To verify this is working correctly, you can check Nutanix Objects browser to see if your artifacts are created and show up inside your buckets.