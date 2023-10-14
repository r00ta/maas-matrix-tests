import sys
import os 
import json

test_results_path = os.path.dirname(os.path.realpath(__file__)).replace(".github", ".test-results")
print(test_results_path)
if __name__ == '__main__':
    snap_version = sys.argv[1]
    message = sys.argv[2]
    test_outcome = sys.argv[3]
    file = test_results_path + "/" + snap_version.replace("/", "-") + ".json"   
    with open(file, "r") as f:
        data = json.loads(f.read())
        print("I've read'" + json.dumps(data) + "' from the file " + file)
        data["color"] = "green" if test_outcome == "success" else "red"
        data["message"] = message
    with open(file, "w") as f:
        print("Writing '" + json.dumps(data) + "' to the file " + file)
        f.write(json.dumps(data))
