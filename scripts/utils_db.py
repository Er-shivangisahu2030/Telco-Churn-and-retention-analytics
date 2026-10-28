"""Shared MySQL connection helper. Credentials are read from a local .env file
(project root), never hardcoded here."""

import os

import mysql.connector

PROJECT_ROOT = os.path.join(os.path.dirname(__file__), "..")
ENV_PATH = os.path.join(PROJECT_ROOT, ".env")


def _load_env():
    if not os.path.exists(ENV_PATH):
        return
    with open(ENV_PATH, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())


_load_env()


_UNSET = object()


def get_connection(database=_UNSET):
    """Return a mysql.connector connection. Pass database=None to connect
    without selecting a database (used when creating the schema). Omit the
    argument entirely to use the MYSQL_DB env var."""
    if database is _UNSET:
        database = os.environ.get("MYSQL_DB")
    kwargs = dict(
        host=os.environ.get("MYSQL_HOST", "localhost"),
        port=int(os.environ.get("MYSQL_PORT", "3306")),
        user=os.environ.get("MYSQL_USER", "root"),
        password=os.environ.get("MYSQL_PASSWORD", ""),
    )
    if database is not None:
        kwargs["database"] = database
    return mysql.connector.connect(**kwargs)


def get_db_name():
    return os.environ.get("MYSQL_DB", "telco_churn")
