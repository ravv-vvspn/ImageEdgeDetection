from PIL import Image

#flag =1 #sobel   62x62
#flag =2 #pool stride1   61x61
#flag =3 #pool stride2 31x31
flag = 3 

# Input text file path
input_txt_path = r"output_pixels.txt"

# Output image path

# Image size
if (flag==1):
    width, height = 62, 62
    output_image_path = r"out7b_p62.png"
elif (flag==2):
    width, height = 61, 61 # needed when circuit was missing to create 4 pixels at output
    output_image_path = r"out7b_p61.png"
elif (flag==3):
    width, height = 31, 31
    output_image_path = r"out7b_512_128_hold_impSUCCESS.png"
    
    

# Read hex values from file
with open(input_txt_path, "r") as f:
    hex_values = f.read().splitlines()  # Read each line and store as list

# Convert hex to integer (grayscale values)
pixel_values = [int(x, 16) for x in hex_values]

# Ensure the correct number of pixels
if len(pixel_values) != width * height:
    raise ValueError("Incorrect number of pixels. Expected {}, found {}.".format(width * height, len(pixel_values)))

# Create image from pixel values
img = Image.new("L", (width, height))  # "L" mode for 8-bit grayscale
img.putdata(pixel_values)  # Set pixel data

# Save the image
img.save(output_image_path)
print("Image saved at:", output_image_path)
