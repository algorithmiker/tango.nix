from pathlib import Path
import argparse
import logging
import os
import subprocess
import dataclasses

logger = logging.getLogger("TangoDBManager")

class DBCreateException(Exception):
  "Failed to create tango database"
  message: str | None

  def __init__(self, message: str):
      super().__init__(message)
      self.message=message
  
  def __str__(self): return f"Failed to create tango database: {self.message}"


def main(args: argparse.Namespace):
  logger.info("Checking if database exists")
  use_tango_cmd = subprocess.run(["mysql", "-e", "use tango"], capture_output=True, text=True, encoding="utf-8")
  logger.info(f"`mysql -e use tango` stdout:\n{use_tango_cmd.stdout}\nstderr:\n{use_tango_cmd.stderr}")
  if use_tango_cmd.returncode == 0:
    logger.info("DB exists, nothing left to do")
    return

  logger.info("DB doesn't exist, will try to create.")
  sql_path: Path = Path(args.sql_path)
  logger.info(f"using SQL path {sql_path}")
  
  os.chdir(sql_path)
  with open(sql_path / "create_db.sql", "r") as create_db_file:
    create_return = subprocess.run(["mysql"], stdin=create_db_file, capture_output=True, text=True)
    if create_return.returncode != 0:
      logger.error(f"create script returned error:\n{create_return.stderr}")
      raise DBCreateException(message=create_return.stderr)

  logger.info(f"create returned: {create_return}")
  logger.info("Done")


if __name__ == "__main__":
  logging.basicConfig(level=logging.INFO)
  parser = argparse.ArgumentParser(prog="TangoDBManager")
  _ = parser.add_argument("-s", "--sql-path", type=str, required=True)
  args = parser.parse_args()
  main(args)
