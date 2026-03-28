import os
from PIL import Image

def generate_mac_icon(source_path, output_dir):
    """
    Generates macOS icons with proper padding (Apple style).
    - Canvas: Square
    - Content: Scaled to ~82.5% of canvas size
    - Padding: Transparent
    """
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    try:
        # Load source image
        original_img = Image.open(source_path).convert("RGBA")
        print(f"Loaded source image: {source_path} ({original_img.size})")
        
        # Define target sizes
        sizes = [16, 32, 64, 128, 256, 512, 1024]
        
        for size in sizes:
            # Create transparent canvas
            canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            
            # Calculate scaled logo size (82.5% of canvas)
            # This follows macOS Big Sur+ icon guidelines loosely for "App Icon" look
            logo_size = int(size * 0.825)
            
            # Resize original logo to logo_size (High quality downsampling)
            resized_logo = original_img.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
            
            # Calculate position to center
            offset = (size - logo_size) // 2
            
            # Paste logo onto canvas
            canvas.paste(resized_logo, (offset, offset), resized_logo)
            
            # Save
            filename = f"icon_{size}x{size}.png"
            output_path = os.path.join(output_dir, filename)
            canvas.save(output_path, "PNG")
            print(f"Generated: {filename}")
            
        print("✅ All icons generated successfully with padding!")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    source_file = "logo*80.png"
    output_directory = "."
    generate_mac_icon(source_file, output_directory)
