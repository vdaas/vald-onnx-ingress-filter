# vald-onnx-ingress-filter

[![Snyk](https://img.shields.io/snyk/vulnerabilities/github/vdaas/vald-onnx-ingress-filter)]()
[![docker image](https://img.shields.io/docker/pulls/vdaas/vald-onnx-ingress-filter?label=vdaas%2Fvald-onnx-ingress-filter&logo=docker&style=flat-square)](https://hub.docker.com/r/vdaas/vald-onnx-ingress-filter)

`vald-onnx-ingress-filter` is one of the official ingress filter components provided by Vald.

Its custom logic requires the input of the ONNX model as a request and outputs the result from the ONNX model as the request of the Vald Agent.

Using this component lets users vectorize various data such as text and images using the ONNX model only inside the Vald cluster without external APIs.

## Usage

### Deploy vald-onnx-ingress-filter

```
git clone https://github.com/vdaas/vald-onnx-ingress-filter.git
kubectl apply -f vald-onnx-ingress-filter/k8s
```

NOTE: The example manifest files use ResNet50-v2 from [ONNX Model Zoo](https://github.com/onnx/models#onnx-model-zoo) as the ONNX model.
You can change the model by editing `k8s/deployment.yaml`.

```
...
  - |
    curl -L "https://github.com/onnx/models/raw/main/vision/classification/resnet/model/resnet50-v2-7.onnx" -o /model/sample.onnx  #FIXME
```

### Deploy Vald cluster with filter gateway

Please edit the example/helm/values.yaml in the Vald repository to make vald-filter-gateway available and use it for deployment.

```
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

```
helm install vald vald/vald --values example/helm/values.yaml
```

## Sample code with [vald-client-python](https://github.com/vdaas/vald-client-python)

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

## Reference

- Medium: [Vald released the new Vald official ingress filter: vald-onnx-ingress-filter
](https://vdaas-vald.medium.com/vald-released-the-new-vald-official-ingress-filter-vald-onnx-ingress-filter-b807e147188b)

- [Open Neural Network Exchange (ONNX)](https://onnx.ai/)
