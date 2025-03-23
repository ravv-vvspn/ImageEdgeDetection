from PIL import Image

# Flags
  # 0 = No change, 1 = Substitute last 20 values
flag2 = 0

# Input image path
image_path = r"test7.png"
output_coe_path = r"input_pixels.coe"

# Open the image and convert it to grayscale (8-bit)
img = Image.open(image_path).convert("L")

# Ensure the image is 64x64
if img.size != (64, 64):
    raise ValueError("The image must be exactly 64x64 pixels.")

# Get pixel data as a list (row-major order)
pixels = list(img.getdata())

# If flag2 is set, replace the last 20 pixel values
# useful for waveform debugging to understand circuit function better
if flag2 == 1:
    substitute_values = [
        0x00, 0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef, 0xa1,
        0xb1, 0xc1, 0xd1, 0xe1, 0xf1, 0xa2, 0xb2, 0xc2, 0xd2, 0xe2
    ]
    
    # Replace the last 20 pixels (indices 4079 to 4098)
    pixels[-20:] = substitute_values

# Write pixel values in hexadecimal format to .coe file
with open(output_coe_path, "w") as f:
    # Write the required header lines
    f.write("memory_initialization_radix=16;\n")
    f.write("memory_initialization_vector=\n")

    # Write pixel data in hex (2-digit lowercase) with commas
    for i, pixel in enumerate(pixels):
        if i == len(pixels) - 1:
            f.write("{:02x};\n".format(pixel))  # End last value with semicolon
        else:
            f.write("{:02x},\n".format(pixel))  # Comma for all other values

print("COE file saved at:", output_coe_path)
