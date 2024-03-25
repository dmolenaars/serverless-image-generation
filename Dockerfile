FROM python:alpine

COPY ./src/* .

RUN apk add --no-cache --virtual .tmp-build-deps make gcc g++ musl-dev libffi-dev && pip install --no-cache-dir -r requirements.txt && apk del .tmp-build-deps

EXPOSE 7860

ENTRYPOINT ["python", "app.py"]