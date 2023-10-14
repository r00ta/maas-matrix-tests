import sys
import os 
import json
from datetime import datetime

test_results_path = os.path.dirname(os.path.realpath(__file__)).replace(".github", ".test-results")
if __name__ == "__main__":
    snap_version = sys.argv[1]
    upstream_snap_date = datetime.strptime(sys.argv[2], "%Y-%m-%d").date()
    file = test_results_path + "/" + snap_version.replace("/", "-") + ".json"
    with open(file, 'r') as f:
        data = json.loads(f.read())
        latest_run = datetime.strptime(data["message"].split("tested at ")[1], "%Y-%m-%d").date()
        if upstream_snap_date > latest_run or data["color"] == "red":
            print("run=true")
        else:
            print("run=false")
