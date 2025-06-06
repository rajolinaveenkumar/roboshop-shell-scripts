#!/bin/bash

log_line="/var/log/messages"

# Extract JSON using grep + sed
json=$(echo "$log_line" | grep -oP 'Order \K\{.*')

# Parse fields using jq
order_id=$(echo "$json" | jq -r '.orderid')
user=$(echo "$json" | jq -r '.user')
price=$(echo "$json" | jq -r '.cart.total')
items=$(echo "$json" | jq -r '.cart.items[] | "\(.name) - ₹\(.price) x \(.qty)"')

echo $order_id
echo $user