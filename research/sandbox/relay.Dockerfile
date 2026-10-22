FROM python:3.12-slim
COPY relay.py /opt/reference/relay.py
USER 1000:1000
ENTRYPOINT ["python3", "/opt/reference/relay.py"]
