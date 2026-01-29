"""
Flask API Gateway - Phase 2
REST API that bridges the React frontend to RabbitMQ.
POST /task  -> publishes a task to the "tasks" queue
GET /results -> consumes available results from the "results" queue
"""

import json
import os

import pika
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

RABBITMQ_HOST = os.environ.get("RABBITMQ_HOST", "rabbitmq-svc")
RABBITMQ_PORT = int(os.environ.get("RABBITMQ_PORT", 5672))
RABBITMQ_USER = os.environ.get("RABBITMQ_USER", "admin")
RABBITMQ_PASS = os.environ.get("RABBITMQ_PASS", "secret")

TASKS_QUEUE = "tasks"
RESULTS_QUEUE = "results"


def get_connection():
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    params = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        heartbeat=600,
    )
    return pika.BlockingConnection(params)


@app.route("/task", methods=["POST"])
def submit_task():
    """Accept a task JSON and publish it to the RabbitMQ tasks queue."""
    data = request.get_json(force=True)
    if not data:
        return jsonify({"error": "Request body must be JSON"}), 400

    task_type = data.get("type", "")
    if task_type not in ("math", "text"):
        return jsonify({"error": "Task 'type' must be 'math' or 'text'"}), 400

    try:
        connection = get_connection()
        channel = connection.channel()
        channel.queue_declare(queue=TASKS_QUEUE, durable=True)
        channel.basic_publish(
            exchange="",
            routing_key=TASKS_QUEUE,
            body=json.dumps(data),
            properties=pika.BasicProperties(delivery_mode=2),
        )
        connection.close()
        return jsonify({"status": "queued", "task": data}), 202
    except Exception as e:
        return jsonify({"error": f"Failed to publish task: {e}"}), 500


@app.route("/results", methods=["GET"])
def get_results():
    """Drain all available messages from the results queue and return them."""
    try:
        connection = get_connection()
        channel = connection.channel()
        channel.queue_declare(queue=RESULTS_QUEUE, durable=True)

        results = []
        while True:
            method, _, body = channel.basic_get(queue=RESULTS_QUEUE, auto_ack=True)
            if method is None:
                break
            results.append(body.decode())

        connection.close()
        return jsonify({"results": results}), 200
    except Exception as e:
        return jsonify({"error": f"Failed to read results: {e}"}), 500


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
