FROM python:alpine3.17

RUN adduser -D runtime
WORKDIR /runtime/app
USER runtime

RUN pip install minio requests --user
COPY bucket_creator.py .

ENTRYPOINT [ "python3", "-u", "/runtime/app/bucket_creator.py" ]
CMD [ "${S3_URL}", "${S3_ACCESS_KEY}", "${S3_SECRET_KEY}", "${DELAY_MIN}", "${DELAY_S}" ]