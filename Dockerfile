FROM python:3.12-slim-bookworm

COPY ./src/* .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 7860

ENTRYPOINT ["python", "app.py"]