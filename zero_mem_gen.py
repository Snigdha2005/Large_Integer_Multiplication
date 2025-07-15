def generate_zero_mem(filename, width, depth, binary=False):
    """
    Generate a .mem file with given width and depth filled with zeros.
    
    Args:
        filename (str): Output filename, e.g., 'init.mem'
        width (int): Bit-width per word (e.g., 76)
        depth (int): Number of lines (e.g., 4097)
        binary (bool): If True, use binary format for $readmemb; else hex for $readmemh
    """
    with open(filename, 'w') as f:
        for _ in range(depth):
            if binary:
                zero_str = '0' * width  # binary string of 0s
            else:
                # Round up to full hex digits (4 bits per hex digit)
                hex_digits = (width + 3) // 4
                zero_str = '0' * hex_digits
            f.write(zero_str + '\n')

    print(f"✅ Generated '{filename}' with {depth} lines of {width}-bit {'binary' if binary else 'hex'} zeros.")


# Example usage:
if __name__ == "__main__":
    # Modify these parameters as needed
    generate_zero_mem(
        filename="zero.mem",
        width=268,
        depth=4095,
        binary=False  # set to True if using $readmemb instead of $readmemh
    )
