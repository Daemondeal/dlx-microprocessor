#!/bin/python3

import random

def generate_division_testvector(amount):
    with open("./testvectors/division.mem", "w") as div_file:
        def write_division(dividend, divisor):
            quotient = (dividend // divisor) & (2**32-1)
            remainder = abs(dividend % divisor) & (2**32-1)

            dividend &= (2**32-1)
            divisor &= (2**32-1)
            div_file.write(f"{dividend:08X}\n")
            div_file.write(f"{divisor:08X}\n")
            div_file.write(f"{quotient:08X}\n")
            div_file.write(f"{remainder:08X}\n")

        # Simple
        dividend = 26
        divisor = 4

        write_division(dividend, divisor)

        # Simple Negative
        dividend = -13
        divisor = 2

        write_division(dividend, divisor)

        # Totally random
        for _ in range(amount):
            dividend = random.randint(1, 2**31-1)
            divisor = random.randint(1, 2**31-1)

            write_division(dividend, divisor)


        # Dividend >> Divisor
        for _ in range(amount):
            dividend = random.randint(2**15-1, 2**31-1)
            divisor = random.randint(1, 2**13-1)

            write_division(dividend, divisor)

        # Negative Dividend
        for _ in range(amount):
            dividend = random.randint(2**15-1, 2**31-1) * -1
            divisor = random.randint(1, 2**13-1)

            write_division(dividend, divisor)

        # Negative Divisor
        for _ in range(amount):
            dividend = random.randint(2**15-1, 2**31-1)
            divisor = random.randint(1, 2**13-1) * -1

            write_division(dividend, divisor)

        # Negative Both
        for _ in range(amount):
            dividend = random.randint(2**15-1, 2**31-1) * -1
            divisor = random.randint(1, 2**13-1) * -1

            write_division(dividend, divisor)


def main():
    random.seed(10)
    generate_division_testvector(amount = 1000)

if __name__ == "__main__":
    main()
