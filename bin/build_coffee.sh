#!/usr/bin/env bash
script_dir=$(dirname "$(realpath "$0")")
image_dir="${script_dir}/../images"

get_creation_time() {
    datetime=$(identify -format "%[EXIF:DateTimeOriginal]" "$1")
    IFS=': ' read -r year month day hour minute second <<< "$datetime"
    s=$(date -d "$year-$month-$day $hour:$minute:$second" +%s)
    if [ -n "$datetime" ]; then
        echo "$s"
    fi
}

IFS=$'\n' coffee_images=( $(find "$image_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \)) )
array=()

echo "1. getting images and creating array ..."
echo "total ${#coffee_images[@]}"
for img in "${coffee_images[@]}"; do
    src=$(basename "$img")
    echo $src
    creation_date=$(get_creation_time "$img") 
    array+=("$src|$creation_date")
done

echo "2. sorting array ..."
IFS=$'\n' sorted=($(sort -t '|' -k2 <<<"${array[*]}")); unset IFS
total="${#sorted[@]}"

cp "${script_dir}/../bin/template.html" "${script_dir}/../index.html"

echo "3. making li elements ..."
order=0
for each in "${sorted[@]}"; do
    IFS='|' read -r -a parts <<< "$each"
    src="./images/${parts[0]}"
    creation_date="${parts[1]}"
    date=$(date -d "@$creation_date" "+%Y-%m-%d %H:%M:%S")
    echo "$src - $creation_date $order"
    list="<li data-order=\"$order\" data-date=\"$date\"><img title=\"$date\" alt=\"$date\" src=\"$src\" loading="lazy"></li>"
    # Append the list item to the placeholder in index.html
    sed -i'' -e "/{{coffeeshere}}/ a $(printf '%s\n' "$list" | sed -e 's/[\/&]/\\&/g')" "${script_dir}/../index.html"
    order=$((order + 1))
done


function generateJSON() {
    local current_year=$(date +"%Y")
    local last_year=$((current_year - 1))
    local latest_coffee=""
    local this_year_total=0
    local last_year_total=0
    local today=$(date +%j)
    local yearTotalDays=365

    function isLeap() { 
        local year=$1
        if (( !(year % 4) && ( year % 100 || !(year % 400) ) )); then
            echo 366
        else
            echo 365
        fi
    }

    for each in "${sorted[@]}"; do
        IFS='|' read -r -a parts <<< "$each"
        creation_date="${parts[1]}"
        year=$(date -d "@$creation_date" +"%Y")
        date=$(date -d "@$creation_date" "+%Y-%m-%d %H:%M:%S")

        if [[ "$creation_date" -gt "$latest_coffee_date" ]]; then
            latest_coffee_date="$creation_date"
            latest_coffee="$date"
        fi
        
        if [[ "$year" == "$current_year" ]]; then
            this_year_total=$((this_year_total + 1))
        elif [[ "$year" == "$last_year" ]]; then
            last_year_total=$((last_year_total + 1))
        fi
    done

    local last_year_days=$(isLeap $last_year)
    local this_year_per_day=$(awk "BEGIN {printf \"%.2f\", $this_year_total / $today}")
    local last_year_per_day=$(awk "BEGIN {printf \"%.2f\", $last_year_total / $last_year_days}")

    # Create JSON
    cat <<EOF > "${script_dir}/../tmi.json"
{   
    "total": "${#sorted[@]}",
    "thisYearTotal": $this_year_total,
    "lastYearTotal": $last_year_total,
    "latestCoffee": "$latest_coffee",
    "thisYearPerDay": "$this_year_per_day",
    "lastYearPerDay" : "$last_year_per_day"
}
EOF
}

generateJSON

sed -i'' -e '/{{coffeeshere}}/d' "${script_dir}/../index.html"
echo "index.html created successfully."