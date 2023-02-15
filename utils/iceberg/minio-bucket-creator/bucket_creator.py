from minio import Minio
from minio.error import S3Error
from os.path import expandvars
from requests import get, RequestException
from sys import argv
from time import sleep


BUCKET_NAME = "iceberg.resurface"

def main():
    def check(*paths):
        for path in paths:
            r = get('http://' + HOSTPORT + path)
            if not r.ok:
                print(r.status_code, r.reason)
                print(r.text)
                return r.ok
        return True
    

    s3_args = argv[1:]
    if len(s3_args) < 3:
        print("This script requires atleast three arguments")
        return

    HOSTPORT, ACCESSKEY, SECRETKEY, *TIME = map(expandvars, s3_args)
    print("Connection arguments passed:",
        f"\tHost: {HOSTPORT}",
        f"\tAccess key: {ACCESSKEY}",
        f"\tSecret key: {SECRETKEY}",
        sep='\n'
    )      

    # (minutes, seconds) to wait before re-trying initial healthcheck
    wait_time = tuple(int(t) if t.isnumeric() else 0 for t in TIME[:2])
    if len(wait_time) != 2 or sum(wait_time) == 0:
        wait_time = (0, 30)  

    print("Performing initial healthchecks")
    while True:
        try:
            healthy = check("/minio/health/live", "/minio/health/ready")
            if not healthy:
                print("MinIO Cluster reachable but not healthy. Exiting now")
                exit(1)
        except (RequestException, OSError) as exception:
            print(exception)
            print(
                "An exception was raised while performing initial healthchecks",
                f"MinIO cluster might not be ready yet. Sleeping for {wait_time[0] + wait_time[1] / 60:.1f} minute(s)",
                sep='\n'
            )
            sleep(wait_time[0] * 60 + wait_time[1])
        else:
            break

    print("Initial healthchecks successful. Connecting to MinIO server")
    client = Minio(
        HOSTPORT,
        access_key=ACCESSKEY,
        secret_key=SECRETKEY,
        secure=False
    )

    found = client.bucket_exists(BUCKET_NAME)
    if not found:
        print(f"Creating {BUCKET_NAME} bucket")
        client.make_bucket(BUCKET_NAME)
    else:
        print(f"Bucket {BUCKET_NAME} already exists")


if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)
    finally:
        print("All done. Bye!")