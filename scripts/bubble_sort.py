"""
Bubble sort algorithm implementation.

Examples
--------
python -m scripts.bubble_sort
"""
from copy import deepcopy
from datetime import datetime


def bubble_sort(array: list) -> list:
    """Sort list using bubble sort algorithm."""
    start = datetime.now()
    # operate on object copy instead of reference
    lst = deepcopy(array)
    k = len(lst)
    for i in range(k - 1):
        for j in range(0, k - i - 1):
            if lst[j] > lst[j + 1]:
                lst[j], lst[j + 1] = lst[j + 1], lst[j]
    print(f"\033[92mElapsed time: {datetime.now() - start}\033[0m")
    return lst


arr = [64, 34, 25, 12, 22, 11, 90]
print(bubble_sort(arr))
