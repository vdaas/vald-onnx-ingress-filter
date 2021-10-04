#
# Copyright (C) 2019-2022 vdaas.org vald team <vald@vdaas.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG DISTROLESS_IMAGE=gcr.io/distroless/python3-debian11
ARG DISTROLESS_IMAGE_TAG=nonroot
ARG MAINTAINER="vdaas.org vald team <vald@vdaas.org>"

FROM python:3.9-slim AS build

COPY requirements.txt /requirements.txt

RUN apt-get update \
    && apt-get install --no-install-suggests --no-install-recommends --yes \
      gcc \
      libpython3-dev \
    && pip install --upgrade pip \
    && pip install --disable-pip-version-check -r /requirements.txt

# Copy the site-pacakges into a distroless image
FROM ${DISTROLESS_IMAGE}:${DISTROLESS_IMAGE_TAG}
LABEL maintainer "${MAINTAINER}"

ENV APP_NAME onnx

USER nonroot:nonroot

COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/dist-packages
COPY main.py /app/main.py
COPY src /app/src

WORKDIR /app
ENTRYPOINT ["python", "-u", "main.py", "--model_path", "/path/to/model.onnx"]
