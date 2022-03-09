import argparse
import grpc
import numpy as np
import onnxruntime

from concurrent import futures
from vald.v1.payload import payload_pb2
from vald.v1.filter.ingress.ingress_filter_pb2_grpc import (
        FilterServicer,
        add_FilterServicer_to_server,
)

parser = argparse.ArgumentParser(description="Implementation of ONNX Ingress Filter")
parser.add_argument("--model_path", type=str, default="/path/to/model",
                    help="path to model directory")


class OnnxFilterServicer(FilterServicer):

    def __init__(self, model_path):
        super().__init__()
        self.sess = onnxruntime.InferenceSession(model_path, None, None, None)
        self.inputs_name = [node.name for node in self.sess.get_inputs()]
        self.outputs_name = [node.name for node in self.sess.get_outputs()]
        assert len(self.inputs_name) == 1
        assert len(self.outputs_name) == 1
        print("input:", self.inputs_name)
        print("output:", self.outputs_name)

    def GenVector(self, request, context):
        reshape_vector = payload_pb2.Object.ReshapeVector()
        reshape_vector.ParseFromString(request.object)

        data = np.frombuffer(reshape_vector.object, dtype=np.float32)
        data = data.reshape(reshape_vector.shape)
        outputs = self.sess.run(self.outputs_name, {self.inputs_name[0]: data}, None)
        outputs = outputs[0].flatten()

        vec = payload_pb2.Object.Vector(id=request.id, vector=outputs)
        return vec

    def FilterVector(self, request, context):
        return request


def main():
    args = parser.parse_args()

    # start gRPC server
    print("start server...")
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=3))
    add_FilterServicer_to_server(OnnxFilterServicer(args.model_path), server)
    server.add_insecure_port('[::]:8081')
    server.start()
    server.wait_for_termination()


if __name__ == "__main__":
    main()
