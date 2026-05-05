from mtd.celery_app import celery


@celery.task(name="mtd.debug")
def debug():
    print("beat fired")
