import argparse
import logging
import os
import subprocess

logger = logging.getLogger("TangoDBManager")

class DBCreateException(Exception):
  "Failed to create tango database"

  source: Exception | None
  message: str | None

  def __init__(self, source: Exception | None = None, message: str | None = None) -> None:
    self.source = source
    self.message = message
    super().__init__()

  pass


def main(args: argparse.Namespace):
  logger.info("Checking database")
  db_exists = subprocess.run(["mysql", "-e", "use tango"]).returncode == 0
  if db_exists:
    logger.info("DB exists, nothing left to do")
    return
  logger.info("DB doesn't exist, will try to create.")
  logger.info(f"will run {args.create_db_sql}")

  with open(args.create_db_sql, "r") as create_db_file:
    create_return = subprocess.run(["mysql"], stdin=create_db_file, capture_output=True, text=True)
    if create_return.returncode != 0:
      logger.error(f"create script returned error:\n{create_return.stderr}")
      raise DBCreateException(message=create_return.stderr)

  logger.info(f"create returned: {create_return}")
  logger.info("Done")


if __name__ == "__main__":
  logging.basicConfig(level=logging.INFO)
  parser = argparse.ArgumentParser(prog="TangoDBManager")
  _ = parser.add_argument("-s", "--create-db-sql", type=str, required=True)
  args = parser.parse_args()
  main(args)
