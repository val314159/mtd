import os

from celery import Celery


celery = Celery("your_app")

db_url = (
    f"postgresql+psycopg2://"
    f"{os.environ['PGUSER']}@{os.environ['PGHOST']}:"
    f"{os.environ['PGPORT']}/{os.environ['PGDATABASE']}"
)

celery.conf.broker_url = f"sqla+{db_url}"
celery.conf.result_backend = f"db+{db_url}"
