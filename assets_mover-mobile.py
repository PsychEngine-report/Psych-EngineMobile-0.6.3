import os
import shutil

# Get the directory where this script file is located
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))

print("=========================================")
# Print everything in the current directory to see what Python sees
print("Files and folders found in the current directory:")
for item in os.listdir(ROOT_DIR):
    if os.path.isdir(os.path.join(ROOT_DIR, item)):
        print(f" [FOLDER] -> {item}")
    else:
        print(f" [FILE]   -> {item}")
print("=========================================\n")

# Hardcoded fallback check for standard base asset folders (lowercased/checked dynamically)
POSSIBLE_BASE_DIRS = ["preload", "shared", "exclude", "secrets", "mobile"]

def get_all_target_directories():
    targets = []
    
    # Try to find where the assets folder actually is
    assets_path = None
    for item in os.listdir(ROOT_DIR):
        if item.lower() == "assets" and os.path.isdir(os.path.join(ROOT_DIR, item)):
            assets_path = os.path.join(ROOT_DIR, item)
            break
            
    if not assets_path:
        print("CRITICAL: Could not find an 'assets' folder in this directory!")
        return targets

    # 1. Scan the main subfolders inside assets
    for subfolder in os.listdir(assets_path):
        subfolder_path = os.path.join(assets_path, subfolder)
        if os.path.isdir(subfolder_path):
            if subfolder.lower() in POSSIBLE_BASE_DIRS:
                targets.append(subfolder_path)
            
    # 2. Automatically find week folders inside 'assets/' if it exists
    week_assets_dir = os.path.join(assets_path)
    if os.path.exists(week_assets_dir) and os.path.isdir(week_assets_dir):
        for item in os.listdir(week_assets_dir):
            item_path = os.path.join(week_assets_dir, item)
            if os.path.isdir(item_path) and item.lower().startswith("week"):
                targets.append(item_path)
                    
    return targets

def sort_folder(base_path):
    png_dir = os.path.join(base_path, "images")
    
    if not os.path.exists(png_dir):
        png_dir = os.path.join(base_path, "images-png")
        if not os.path.exists(png_dir):
            return None

    astc_dir = os.path.join(base_path, "images-astc")

    has_astc = False
    for root, dirs, files in os.walk(png_dir):
        if any(file.endswith(".astc") for file in files):
            has_astc = True
            break

    if not has_astc:
        print(f"Skipping {os.path.basename(base_path)}: Found 0 .astc files inside images/images-png.")
        if png_dir == os.path.join(base_path, "images"):
            os.rename(png_dir, os.path.join(base_path, "images-png"))
        return None

    old_temp = os.path.join(base_path, "images-astc_TEMP")
    if os.path.exists(old_temp):
        shutil.rmtree(old_temp)

    os.makedirs(astc_dir, exist_ok=True)
    print(f"Scanning and sorting files from {os.path.basename(png_dir)}...")

    folder_counts = {"png": 0, "astc": 0, "metadata_other": 0}

    for root, dirs, files in os.walk(png_dir):
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, png_dir)
            dest = os.path.join(astc_dir, rel_path)
            
            if file.endswith(".astc"):
                if os.path.exists(dest):
                    folder_counts["astc"] += 1
                    continue
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                shutil.move(file_path, dest)
                folder_counts["astc"] += 1
                
            elif file.endswith(".png"):
                folder_counts["png"] += 1
                
            else:
                if os.path.exists(dest):
                    folder_counts["metadata_other"] += 1
                    continue
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                shutil.copy2(file_path, dest)
                folder_counts["metadata_other"] += 1

    if png_dir == os.path.join(base_path, "images"):
        os.rename(png_dir, os.path.join(base_path, "images-png"))
    
    print(f" -> Done with {os.path.basename(base_path)}!\n")
    return folder_counts

if __name__ == "__main__":
    total_counts = {"png": 0, "astc": 0, "metadata_other": 0}
    folders_processed = 0

    TARGET_DIRS = get_all_target_directories()

    print("Found target directories to scan:")
    for d in TARGET_DIRS:
        print(f" - {os.path.relpath(d, ROOT_DIR)}")
    print("-----------------------------------------\n")

    for folder in TARGET_DIRS:
        if os.path.exists(folder):
            counts = sort_folder(folder)
            if counts:
                folders_processed += 1
                total_counts["png"] += counts["png"]
                total_counts["astc"] += counts["astc"]
                total_counts["metadata_other"] += counts["metadata_other"]
                

    print("=========================================")
    print("      FINAL SUMMARY BREAKDOWN            ")
    print("=========================================")
    print(f"Folders organized:     {folders_processed}")
    print(f"PNG files preserved:   {total_counts['png']}")
    print(f"ASTC files extracted:  {total_counts['astc']}")
    print(f"Metadata files copied: {total_counts['metadata_other']}")
    print("-----------------------------------------")
    print("Process complete!")
    print("=========================================")
    print("\n" + "="*41)
    input("Press ENTER to close this window...")