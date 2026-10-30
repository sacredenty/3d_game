import struct
import zlib
import os

def create_png(path, width, height, pixels):
    """Create a PNG from pixel data (RGBA tuples)"""
    png = b'\x89PNG\r\n\x1a\n'
    
    ihdr_data = struct.pack('>II', width, height) + struct.pack('BBBB', 8, 6, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    ihdr_chunk = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    raw_data = bytes([0])
    for y in range(height):
        raw_data += bytes(pixels[y*width:(y+1)*width])
    
    compressed = zlib.compress(raw_data, 9)
    idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
    idat_chunk = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
    
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    png += ihdr_chunk + idat_chunk + iend_chunk
    
    with open(path, 'wb') as f:
        f.write(png)

# Define tile colors (RGBA tuples)
tile_colors = {
    "grass": [(51, 143, 93, 255)] * 1024,
    "dirt": [(139, 105, 60, 255)] * 1024,
    "sand": [(180, 160, 100, 255)] * 1024,
    "water": [(65, 105, 225, 255)] * 1024,
    "cave_wall": [(105, 105, 105, 255)] * 1024,
    "bush": [(93, 143, 93, 255)] * 1024,
    "fountain": [(169, 169, 169, 255)] * 1024,
    "campfire": [(255, 100, 0, 255)] * 1024,
    "chest": [(165, 42, 42, 255)] * 1024,
    "door": [(101, 67, 33, 255)] * 1024,
    "bridge": [(101, 67, 33, 255)] * 1024,
}

# Create all tile textures
tile_dir = "/home/chris/repos/3d_game/textures"
os.makedirs(tile_dir, exist_ok=True)

for name, color in tile_colors.items():
    create_png(f"{tile_dir}/{name}.png", 32, 32, color)

print("Created all tile textures")
