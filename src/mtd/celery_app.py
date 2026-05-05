import os

from celery import Celery


db_url = (
    f"postgresql+psycopg2://"
    f"{os.environ['PGUSER']}@{os.environ['PGHOST']}:"
    f"{os.environ['PGPORT']}/{os.environ['PGDATABASE']}"
)

celery = Celery(
    "mtd",
    broker=f"sqla+{db_url}",
    backend=f"db+{db_url}",
    include=["mtd.celery_tasks"],
)

celery.config_from_object("mtd.schedule")
