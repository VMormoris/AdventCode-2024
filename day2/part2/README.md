# Day 2 - Part 2
<sub>The following is the relevant puzzle description from [advent of code](https://adventofcode.com/2024/day/2)</sub>

Now, the same rules apply as before, except if removing a single level from an unsafe report would make it safe, the report instead counts as safe.

More of the above example's reports are now safe:

- `7 6 4 2 1`: **Safe** without removing any level.
- `1 2 7 8 9`: **Unsafe** regardless of which level is removed.
- `9 7 6 2 1`: **Unsafe** regardless of which level is removed.
- `1 3 2 4 5`: **Safe** by removing the second level, `3`.
- `8 6 4 4 1`: **Safe** by removing the third level, `4`.
- `1 3 6 7 9`: **Safe** without removing any level.

Thanks to the Problem Dampener, `4` reports are actually **safe**!

Update your analysis by handling situations where the Problem Dampener can remove a single level from unsafe reports. **How many reports are now safe?**

Your puzzle answer was `465`.