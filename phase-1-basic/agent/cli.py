"""
Interactive CLI for the Task Distribution System - Phase 1
Submits tasks to RabbitMQ and displays results inline.

Prerequisites:
    pip install pika
    kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672

Usage:
    python cli.py
"""

import json
import time
import uuid

import pika


RABBITMQ_HOST = "localhost"
RABBITMQ_PORT = 5672
RABBITMQ_USER = "admin"
RABBITMQ_PASS = "secret"

QUEUE_NAME = "tasks"

# Menu text
MAIN_MENU = """
=== Task Distribution System (Phase 1) ===

  [1] Math expression
  [2] Text operation
  [3] Send batch test
  [q] Quit
"""

TEXT_MENU = """
  Text operations:
    [1] reverse
    [2] upper
    [3] lower
    [4] length
"""


def connect():
    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    return pika.BlockingConnection(
        pika.ConnectionParameters(
            host=RABBITMQ_HOST,
            port=RABBITMQ_PORT,
            credentials=credentials,
        )
    )


def send_and_wait(channel, task: dict, timeout: float = 10.0) -> str:
    """Publish a task and wait for the result via a temporary reply queue."""
    result = channel.queue_declare(queue="", exclusive=True)
    callback_queue = result.method.queue
    corr_id = str(uuid.uuid4())

    response = None

    def on_response(_ch, _method, props, body):
        nonlocal response
        if props.correlation_id == corr_id:
            response = body.decode()

    channel.basic_consume(
        queue=callback_queue, on_message_callback=on_response, auto_ack=True
    )

    channel.basic_publish(
        exchange="",
        routing_key=QUEUE_NAME,
        body=json.dumps(task),
        properties=pika.BasicProperties(
            reply_to=callback_queue,
            correlation_id=corr_id,
            delivery_mode=2,
        ),
    )

    # Poll until response arrives or timeout
    deadline = time.time() + timeout
    while response is None and time.time() < deadline:
        channel.connection.process_data_events(time_limit=0.5)

    if response is None:
        return "TIMEOUT: No response from agent (is it running?)"
    return response


def handle_math(channel):
    expr = input("  Enter expression (e.g. factorial(10), sqrt(144), 2**16): ").strip()
    if not expr:
        print("  Cancelled.")
        return

    task = {"type": "math", "expr": expr}
    print(f"  [sent] {json.dumps(task)}")
    result = send_and_wait(channel, task)
    print(f"  [result] {result}")


def handle_text(channel):
    print(TEXT_MENU)
    ops = {"1": "reverse", "2": "upper", "3": "lower", "4": "length"}
    choice = input("  Select operation: ").strip()
    operation = ops.get(choice)
    if not operation:
        print("  Invalid choice.")
        return

    value = input("  Enter text: ").strip()
    if not value:
        print("  Cancelled.")
        return

    task = {"type": "text", "operation": operation, "value": value}
    print(f"  [sent] {json.dumps(task)}")
    result = send_and_wait(channel, task)
    print(f"  [result] {result}")


def handle_batch(channel):
    tasks = [
        {"type": "math", "expr": "factorial(10)"},
        {"type": "math", "expr": "sqrt(144)"},
        {"type": "math", "expr": "2**16"},
        {"type": "text", "operation": "reverse", "value": "kubernetes"},
        {"type": "text", "operation": "upper", "value": "hello world"},
        {"type": "text", "operation": "length", "value": "minikube"},
    ]

    print(f"  Sending {len(tasks)} tasks...\n")
    for task in tasks:
        print(f"  [sent] {json.dumps(task)}")
        result = send_and_wait(channel, task)
        print(f"  [result] {result}\n")

    print(f"  Batch complete: {len(tasks)} tasks processed.")


def main():
    try:
        connection = connect()
    except pika.exceptions.AMQPConnectionError:
        print("ERROR: Cannot connect to RabbitMQ at localhost:5672")
        print("Make sure port-forwarding is active:")
        print("  kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672")
        return

    channel = connection.channel()
    channel.queue_declare(queue=QUEUE_NAME, durable=True)

    try:
        while True:
            print(MAIN_MENU)
            choice = input("> ").strip().lower()

            if choice == "1":
                handle_math(channel)
            elif choice == "2":
                handle_text(channel)
            elif choice == "3":
                handle_batch(channel)
            elif choice == "q":
                break
            else:
                print("  Invalid choice. Try 1, 2, 3, or q.")
    except KeyboardInterrupt:
        print("\n  Interrupted.")
    finally:
        connection.close()
        print("  Goodbye.")


if __name__ == "__main__":
    main()
