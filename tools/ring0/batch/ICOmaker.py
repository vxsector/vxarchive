import os
from PIL import Image

def main():
    print("Where is your source PNG? (e.g. C:/Users/You/Desktop/source.png)")
    src_path = input("> ").strip()

    if not os.path.isfile(src_path):
        print(f"Error: Could not find a file at {src_path}")
        return

    print("Where should I put all the output images? (e.g. C:/Users/You/Desktop/output)")
    out_dir = input("> ").strip()
    os.makedirs(out_dir, exist_ok=True)

    try:
        img = Image.open(src_path).convert("RGBA")
    except Exception as e:
        print(f"Error: Failed to open image. {e}")
        return

    # Define how many copies ("pairs") you want for each size
    # 2 copies of 256×256
    # 2 copies of 64×64
    # 4 copies of 48×48
    # 4 copies of 40×40
    # 4 copies of 32×32
    # 4 copies of 24×24
    # 1 copy of 20×20
    # 4 copies of 16×16
    specs = {
        (256, 256): 2,
        (64,  64): 2,
        (48,  48): 4,
        (40,  40): 4,
        (32,  32): 4,
        (24,  24): 4,
        (20,  20): 1,
        (16,  16): 4,
    }

    base_name = os.path.splitext(os.path.basename(src_path))[0]

    # Generate individual PNGs for each size/copy
    for (w, h), count in specs.items():
        for i in range(1, count + 1):
            resized = img.resize((w, h), Image.LANCZOS)
            filename = f"{base_name}_{w}x{h}_v{i}.ico"
            out_path = os.path.join(out_dir, filename)
            try:
                resized.save(out_path, format="ico")
                print(f"Saved: {filename}")
            except Exception as e:
                print(f"Error saving {filename}: {e}")

    # ==== OPTIONAL: also bundle everything into one multi-size .ico ====
    # If you want a single ICO containing one copy of each size,
    # uncomment this part (and comment it back if you don’t need it).

    """
    # Build a list of sizes (one copy of each) for the ICO
    ico_sizes = [(256,256), (64,64), (48,48), (40,40), (32,32), (24,24), (20,20), (16,16)]
    ico_name = f"{base_name}.ico"
    ico_path = os.path.join(out_dir, ico_name)
    try:
        img.save(ico_path, format="ICO", sizes=ico_sizes)
        print(f"✅ Bundled ICO: {ico_name}")
    except Exception as e:
        print(f"Error saving ICO: {e}")
    """

    print("\nAll done! 🎉")

if __name__ == "__main__":
    main()
