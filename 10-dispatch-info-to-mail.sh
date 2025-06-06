#!/bin/bash

# File to keep track of the last seen order ID
LAST_ORDER_FILE="/tmp/last_order_id.txt"

# Initialize if not exists
if [ ! -f "$LAST_ORDER_FILE" ]; then
  echo "" > "$LAST_ORDER_FILE"
fi

# Loop forever
while true; do
  # Get latest order line
  log_line=$(grep 'Order {' /var/log/messages | tail -n 1)

  # Extract JSON safely
  json=$(echo "$log_line" | grep -oP 'Order \K\{.*')

  # Skip if no JSON found
  if [ -z "$json" ]; then
    sleep 10
    continue
  fi

  # Get order ID
  order_id=$(echo "$json" | jq -r '.orderid')

  # Read the last seen order ID
  last_order_id=$(cat "$LAST_ORDER_FILE")

  # Compare with last seen order
  if [ "$order_id" != "$last_order_id" ]; then
    # New order found — update the last seen order ID
    echo "$order_id" > "$LAST_ORDER_FILE"

    # Extract details
    user=$(echo "$json" | jq -r '.user')
    price=$(echo "$json" | jq -r '.cart.total')
    items=$(echo "$json" | jq -r '.cart.items[] | "\(.name) - ₹\(.price) x \(.qty)"')

    # Print to terminal
    echo "🛒 Order ID: $order_id"
    echo "👤 User: $user"
    echo "💵 Total Price: ₹$price"
    echo "📦 Items:"
    echo "$items"
    echo "-------------------------------------------"
  fi

  # Wait 10 seconds before checking again
  sleep 10
done
