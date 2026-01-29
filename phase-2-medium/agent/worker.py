"""
Agent Worker - Phase 2
Consumes tasks from the RabbitMQ "tasks" queue and processes them.
Supports math expressions (via sympy) and basic text operations.
Results include the pod hostname for observing load balancing.
"""

import json
import os
import socket
import sys
import time

import pika
import sympy


RABBITMQ_HOST = os.environ.get("RABBITMQ_HOST", "localhost")
RABBITMQ_PORT = int(os.environ.get("RABBITMQ_PORT", 5672))
RABBITMQ_USER = os.environ.get("RABBITMQ_USER", "admin")
RABBITMQ_PASS = os.environ.get("RABBITMQ_PASS", "secret")

QUEUE_NAME = "tasks"
RESULTS_QUEUE = "results"

HOSTNAME = socket.gethostname()


def process_task(body: bytes) -> str:
    """Parse and process a task message."""
    try:
        task = json.loads(body)
    except json.JSONDecodeError:
        return f"[{HOSTNAME}] ERROR: Invalid JSON: {body.decode()}"

    task_type = task.get("type", "").lower()

    if task_type == "math":
        return _process_math(task)
    elif task_type == "text":
        return _process_text(task)
    else:
        return f"[{HOSTNAME}] ERROR: Unknown task type '{task_type}'. Use 'math' or 'text'."


def _process_math(task: dict) -> str:
    expr = task.get("expr", "")
    if not expr:
        return f"[{HOSTNAME}] ERROR: 'expr' field is required for math tasks."
    try:
        result = sympy.sympify(expr)
        return f"[{HOSTNAME}] MATH RESULT: {expr} = {result}"
    except (sympy.SympifyError, TypeError, ValueError) as e:
        return f"[{HOSTNAME}] ERROR: Could not evaluate '{expr}': {e}"


def _process_text(task: dict) -> str:
    operation = task.get("operation", "").lower()
    value = task.get("value", "")
    if not value:
        return f"[{HOSTNAME}] ERROR: 'value' field is required for text tasks."

    if operation == "reverse":
        return f"[{HOSTNAME}] TEXT RESULT: reverse('{value}') = '{value[::-1]}'"
    elif operation == "upper":
        return f"[{HOSTNAME}] TEXT RESULT: upper('{value}') = '{value.upper()}'"
    elif operation == "lower":
        return f"[{HOSTNAME}] TEXT RESULT: lower('{value}') = '{value.lower()}'"
    elif operation == "length":
        return f"[{HOSTNAME}] TEXT RESULT: length('{value}') = {len(value)}"
    else:
        return f"[{HOSTNAME}] ERROR: Unknown text operation '{operation}'. Use reverse/upper/lower/length."


def on_message(ch, method, properties, body):
    """Callback invoked for each message consumed from the queue."""
    print(f"[*] Received task: {body.decode()}", flush=True)
    result = process_task(body)
    print(f"[+] {result}", flush=True)

    # Always publish to the results queue (API will read from here)
    ch.basic_publish(
        exchange="",
        routing_key=RESULTS_QUEUE,
        body=result,
        properties=pika.BasicProperties(delivery_mode=2),
    )

    ch.basic_ack(delivery_tag=method.delivery_tag)


def connect_with_retry(max_retries: int = 10, delay: int = 5) -> pika.BlockingConnection:
    """Connect to RabbitMQ with retry logic for startup ordering."""
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    params = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        heartbeat=600,
    )

    for attempt in range(1, max_retries + 1):
        try:
            print(f"[*] {HOSTNAME}: Connecting to RabbitMQ at {RABBITMQ_HOST}:{RABBITMQ_PORT} "
                  f"(attempt {attempt}/{max_retries})...", flush=True)
            connection = pika.BlockingConnection(params)
            print(f"[+] {HOSTNAME}: Connected to RabbitMQ.", flush=True)
            return connection
        except pika.exceptions.AMQPConnectionError:
            if attempt == max_retries:
                print(f"[!] {HOSTNAME}: Max retries reached. Exiting.", flush=True)
                sys.exit(1)
            print(f"[-] {HOSTNAME}: Connection failed. Retrying in {delay}s...", flush=True)
            time.sleep(delay)


def main():
    connection = connect_with_retry()
    channel = connection.channel()

    channel.queue_declare(queue=QUEUE_NAME, durable=True)
    channel.queue_declare(queue=RESULTS_QUEUE, durable=True)
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=QUEUE_NAME, on_message_callback=on_message)

    print(f"[*] {HOSTNAME}: Waiting for tasks on queue '{QUEUE_NAME}'. Press CTRL+C to exit.", flush=True)

    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        print(f"[*] {HOSTNAME}: Shutting down.", flush=True)
        channel.stop_consuming()
    finally:
        connection.close()


if __name__ == "__main__":
    main()
