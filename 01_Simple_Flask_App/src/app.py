from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def home():
    # Create a dictionary that you want to return as JSON
    data = {
        "message": "Hello, Kubernetes!",
        "status": "success"
    }
    # Use jsonify to return the data as a JSON response
    return jsonify(data)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
