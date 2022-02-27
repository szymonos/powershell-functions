#!/bin/bash
: '
Bubble sort algorithm implementation.

bash scripts/bubble_sort.sh
'

bubble_sort() {
    start=$(date +%s%N)
    lst=("$@")
    k="${#lst[@]}"
    flag=1
    for ((i = 0; i < k - 1; i++)); do
        for ((j = 0; j < k - i - 1; j++)); do
            if ((${lst[$j]} > ${lst[$j + 1]})); then
                temp=${lst[$j]}
                lst[$j]=${lst[$j + 1]}
                lst[$j + 1]=$temp
            fi
        done
    done
    printf "\033[92mElapsed time: $(echo "scale=6;($(date +%s%N) - ${start})/(1*10^09)" | bc)s\033[0m\n"
    echo ${lst[@]}
}

arr=(64 34 25 12 22 11 90)
bubble_sort ${arr[@]}
