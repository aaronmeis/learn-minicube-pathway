"""
Test script - run locally to publish sample tasks to RabbitMQ.
Requires: pip install pika

Usage (after port-forwarding RabbitMQ):
    kubectl port-forward -n task-system svc/rabbitmq-svc 5672:5672
    python send_test_task.py
"""

import json
import pika


def main():
    credentials = pika.PlainCredentials("admin", "secret")
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host="localhost", port=5672, credentials=credentials)
    )
    channel = connection.channel()
    channel.queue_declare(queue="tasks", durable=True)

    tasks = [
        {"type": "math", "expr": "factorial(10)"},
        {"type": "math", "expr": "sqrt(144)"},
        {"type": "math", "expr": "2**16"},
        {"type": "text", "operation": "reverse", "value": "kubernetes"},
        {"type": "text", "operation": "upper", "value": "hello world"},
        {"type": "text", "operation": "length", "value": "minikube"},
    ]

    for task in tasks:
        body = json.dumps(task)
        channel.basic_publish(
            exchange="",
            routing_key="tasks",
            body=body,
            properties=pika.BasicProperties(delivery_mode=2),  # persistent
        )
        print(f"[>] Sent: {body}")

    connection.close()
    print(f"\n[+] Published {len(tasks)} tasks. Check agent logs with:")
    print("    kubectl logs -n task-system -l app=agent --follow")


if __name__ == "__main__":
    main()
