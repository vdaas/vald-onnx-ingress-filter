# Vald ONNX Ingress Filter

<!-- introduction sentence -->

`vald-onnx-ingress-filter` is one of the official ingress filter components provided by Vald.

Its custom logic requires the input of the ONNX model as a request and outputs the result from the ONNX model as the request of the Vald Agent.

Using this component lets users vectorize various data such as text and images using the ONNX model only inside the Vald cluster without external APIs.

<div align="center">
    <img src="https://github.com/vdaas/vald/blob/main/assets/image/readme.svg?raw=true" width="50%" />
</div>

[![latest Image](https://img.shields.io/docker/v/vdaas/vald-onnx-ingress-filter/latest?label=vald-onnx-ingress-filter)](https://hub.docker.com/r/vdaas/vald-onnx-ingress-filter/tags?page=1&name=latest)
[![License: Apache 2.0](https://img.shields.io/github/license/vdaas/vald.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![latest ver.](https://img.shields.io/github/release/vdaas/vald.svg?style=flat-square)](https://github.com/vdaas/vald/releases/latest)
[![Twitter](https://img.shields.io/badge/twitter-follow-blue?logo=twitter&style=flat-square)](https://twitter.com/vdaas_vald)

## Requirement

<!-- FIXME: If image has some requirements, describe here with :warning: emoji -->

### linux/amd64

- Libraries: kubectl, Helm, grpcio, numpy, onnxruntime, vald-client-python
- Others: Vald cluster

### linux/arm64

- Libraries: kubectl, Helm, grpcio, numpy, onnxruntime, vald-client-python
- Others: Vald cluster

## Get Started

<!-- Get Started -->
<!-- Vald Agent NGT requires more chapter Agent Standalone -->

`vald-onnx-ingress-filter` is used for ingress filter component of the Vald cluster, which means it should be used on the Kubernetes cluster, not the local environment or Docker.

The steps are following:

1. Deploy vald-onnx-ingress-filter

   ```bash
   git clone https://github.com/vdaas/vald-onnx-ingress-filter.git
   kubectl apply -f vald-onnx-ingress-filter/k8s
   ```

   NOTE: The example manifest files use ResNet50-v2 from [ONNX Model Zoo](https://github.com/onnx/models#onnx-model-zoo) as the ONNX model.
   You can change the model by editing `k8s/deployment.yaml`.

   ```bash
   ...
     - |
       curl -L "https://github.com/onnx/models/raw/main/vision/classification/resnet/model/resnet50-v2-7.onnx" -o /model/sample.onnx  #FIXME
   ```

1. Deploy the Vald cluster with filter gateway

   Please edit the [`example/helm/values.yaml`](https://github.com/vdaas/vald/blob/main/example/helm/values.yaml) in the Vald repository to make vald-filter-gateway available and use it for deployment.

   ```bash
   git clone https://github.com/vdaas/vald.git
   cd vald

   vim example/helm/values.yaml
   ---
   ...
   gateway:
   ...
       filter:
           enabled: true
   ...
   agent:
       ngt:
           dimension: 1000
   ```

   After editing, let’s try to deploy the Vald cluster by the helm install command.

   ```bash
   helm install vald vald/vald --values example/helm/values.yaml
   ```

### Sample code with [vald-client-python](https://github.com/vdaas/vald-client-python)

We use a random vector as an example of the insert object.

```python
import grpc
import numpy as np
from vald.v1.payload import payload_pb2
from vald.v1.vald import (
    filter_pb2_grpc,
    search_pb2_grpc,
)

channel = grpc.insecure_channel("localhost:8081")

// Insert
stub = filter_pb2_grpc.FilterStub(channel)
sample = np.random.random((1, 3, 224, 224)).astype(np.float32)
resize_vector = payload_pb2.Object.ReshapeVector(
    object=sample.tobytes(),
    shape=[1, 3, 224, 224],
)
resize_vector = resize_vector.SerializeToString()

req = payload_pb2.Insert.ObjectRequest(
    object=payload_pb2.Object.Blob(
        id="0",
        object=resize_vector
    ),
    config=payload_pb2.Insert.Config(skip_strict_exist_check=False),
    vectorizer=payload_pb2.Filter.Target(
        host="vald-onnx-ingress-filter",
        port=8081,
    )
)
stub.InsertObject(req)

// Search
sstub = search_pb2_grpc.SearchStub(channel)
scfg = payload_pb2.Search.Config(
    num=10, radius=-1.0, epsilon=0.01, timeout=3000000000
)
sstub.Search(
    payload_pb2.Search.Request(
        vector=np.zeros((1000)),
        config=scfg
    )
)
```

## Versions

| tag     | linux/amd64 | linux/arm64 | description                                                                                                                     |
| :------ | :---------: | :---------: | :------------------------------------------------------------------------------------------------------------------------------ |
| latest  |     ✅      |     ✅      | the latest image is the same as the latest version of [vdaas/vald](https://github.com/vdaas/vald) repository version.           |
| nightly |     ✅      |     ✅      | the nightly applies the main branch's source code of the [vdaas/vald](https://github.com/vdaas/vald) repository.                |
| pr-XXX  |     ✅      |     ❌      | the pr-XXX image applies the source code of the pull request XXX of the [vdaas/vald](https://github.com/vdaas/vald) repository. |

## Dockerfile

<!-- FIXME -->

The `Dockerfile` of this image is [here](https://github.com/vdaas/vald-onnx-ingress-filter/blob/main/Dockerfile).

## About Vald Project

<!-- About Vald Project -->
<!-- This chapter is static -->

The information about the Vald project, please refer to the following:

- [Official website](https://vald.vdaas.org)
- [GitHub](https://github.com/vdaas/vald)

## Contacts

We're love to support you!
Please feel free to contact us anytime with your questions or issue reports.

- [Official Slack WS](https://join.slack.com/t/vald-community/shared_invite/zt-db2ky9o4-R_9p2sVp8xRwztVa8gfnPA)
- [GitHub Issue](https://github.com/vdaas/vald/issues)

## License

This product is under the terms of the Apache License v2.0; refer [LICENSE](https://github.com/vdaas/vald/blob/main/LICENSE) file.
