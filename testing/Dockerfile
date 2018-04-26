FROM alpine:latest

RUN apk add --no-cache python3 \
  && python3 -m ensurepip \
  && pip3 install --upgrade pip
RUN pip3 install dnspython PyYAML requests Flask

COPY ./test-runner.py /root/test-runner.py
ADD tests /root/tests

ENTRYPOINT ["python3", "/root/test-runner.py"]
