# MIPS Bin Packing (First-Fit & Best-Fit)

## Overview
This project implements the **Bin Packing** problem in **MIPS Assembly** using two heuristics:

- **First-Fit (FF)**
- **Best-Fit (BF)**

The program workflow:
1. Prompts the user to enter an **input file name/path** (enter **Q** or **q** to exit).
2. Reads item values from the input file.
3. Validates input values.
4. Prompts the user to select a heuristic (**FF** or **BF**, case-insensitive).
5. Packs items into bins with capacity **1.0**.
6. Writes the final bin distribution to **`output_file.txt`**.

---

## Features
- Reads input values from a text file (one value per line).
- Input validation:
  - Values must start with `0.`
  - Must satisfy **0.0 ≤ x < 1.0**
- Supports **FF** and **BF** heuristic selection.
- Writes results to `output_file.txt` in a clear bin-by-bin format.

---

## Input Format
- Plain text file
- **One item per line**
- Each item must:
  - start with `0.`
  - satisfy **0.0 ≤ x < 1.0**

Example (`input_file.txt`):
```txt
0.4
0.7
0.2
0.05
0.99
```

If the file does not exist or any value is invalid, the program prints an error message and restarts.

---

## How to Run
1. Open `ArchProject1.asm` in a MIPS simulator such as **MARS** or **QtSpim**.
2. Run the program.
3. Enter the input file name/path when prompted.
4. Choose the heuristic:
   - Type `FF` for First-Fit, or
   - Type `BF` for Best-Fit
5. Open `output_file.txt` to view the packing result.

---

## Output
The program writes one line per bin to `output_file.txt` in this format:
```txt
Bin <index>: <total> Items: <item1> <item2> <item3> ...
```

Example:
```txt
Bin 0: 0.96 Items: 0.40 0.20 0.30 0.05 0.01
Bin 1: 0.70 Items: 0.70
```

---

## Files
- `ArchProject1.asm` — MIPS Assembly source code
- `input_file.txt` — sample input file (optional)
- `output_file.txt` — generated output file (created/overwritten after running)

---

## Notes
- `output_file.txt` is generated automatically after each run. You may choose **not** to upload it to GitHub.
- Invalid inputs (negative values, values ≥ 1.0, or not starting with `0.`) will be rejected.

---

## Authors
- Aws Hammad (1221697)
- Ibraheem Sleet (1220200)
