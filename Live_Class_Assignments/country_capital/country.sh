#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 [letter]"
  exit 1
fi

# Fetch the list of world countries and capitals
data=$(curl -s 'https://restcountries.com/v3.1/all')

# Extract country names and capitals that start with the specified letter
letter="$1"
filtered_data=$(echo "$data" | grep -oE '"name":{"common":"[^"]*","official"' | sed -e 's/"name":{"common":"\([^"]*\)","official"/\1/' -e 's/"//g' | grep -i "^$letter")

# Check if any countries match the letter
if [ -z "$filtered_data" ]; then
  echo "No countries found that start with the letter '$letter'."
  exit 0
fi

# Sort the results alphabetically
sorted_data=$(echo "$filtered_data" | LC_ALL=C sort)

# Output the sorted list of countries and capitals
echo -e "Country\tCapital"
while read -r line; do
  country=$(echo "$line" | awk -F',' '{print $1}')
  capital=$(echo "$line" | awk -F',' '{print $2}')
  echo -e "$country\t$capital"
done <<< "$sorted_data"
