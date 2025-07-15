import random

def generate_mem_file(filename, width, depth):
    """
    Generates a .mem file with given width and depth.
    
    Each line will be a binary value of 'width' bits, randomly generated.
    """
    with open(filename, 'w') as f:
        for _ in range(depth):
            value = random.getrandbits(width)
            bin_str = format(value, f'0{width}b')  # zero-padded binary string
            f.write(f'{bin_str}\n')

# ==== Customize these values ====
filename = 'B1.mem'
bit_width = 128        # number of bits per entry
memory_depth = 2048   # number of entries
# ================================

generate_mem_file(filename, bit_width, memory_depth)
print(f"✅ Generated {filename} with width={bit_width} and depth={memory_depth}")
