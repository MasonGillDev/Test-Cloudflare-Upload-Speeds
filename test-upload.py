#!/usr/bin/env python3

import requests
import time
import sys
import os

def format_size(bytes):
    """Convert bytes to human readable format"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes < 1024.0:
            return f"{bytes:.2f} {unit}"
        bytes /= 1024.0
    return f"{bytes:.2f} TB"

def create_test_file(size_mb):
    """Create a test file of specified size in MB"""
    filename = f"test_file_{size_mb}MB.bin"
    print(f"Creating {size_mb}MB test file...")

    with open(filename, 'wb') as f:
        # Write 1MB at a time
        chunk_size = 1024 * 1024  # 1MB
        for _ in range(size_mb):
            f.write(os.urandom(chunk_size))

    print(f"Test file created: {filename}")
    return filename

def upload_file(url, filepath):
    """Upload file and measure time"""
    file_size = os.path.getsize(filepath)
    filename = os.path.basename(filepath)

    print(f"\nUploading {filename} ({format_size(file_size)}) to {url}...")
    print("=" * 60)

    start_time = time.time()

    with open(filepath, 'rb') as f:
        files = {'files': (filename, f)}
        response = requests.post(f"{url}/upload", files=files)

    end_time = time.time()
    upload_time = end_time - start_time

    if response.status_code == 200:
        data = response.json()
        speed_mbps = (file_size * 8 / upload_time / 1000000)
        speed_mbytes = (file_size / upload_time / 1024 / 1024)

        print(f"\n✓ Upload successful!")
        print(f"  Files Uploaded: {data['count']}")
        print(f"  Total Size: {format_size(file_size)}")
        print(f"  Upload Time: {upload_time:.2f}s")
        print(f"  Average Speed: {speed_mbps:.2f} Mbps ({speed_mbytes:.2f} MB/s)")
        print("=" * 60)

        return True
    else:
        print(f"\n✗ Upload failed: {response.status_code}")
        print(f"  Response: {response.text}")
        return False

def main():
    # Default values
    default_url = "http://localhost:5000"
    default_size = 100

    # Parse arguments
    if len(sys.argv) > 1:
        url = sys.argv[1]
    else:
        url = default_url

    if len(sys.argv) > 2:
        try:
            size_mb = int(sys.argv[2])
        except ValueError:
            print("Error: Size must be a number (MB)")
            sys.exit(1)
    else:
        size_mb = default_size

    print("=" * 60)
    print("Upload Speed Test")
    print("=" * 60)
    print(f"Target URL: {url}")
    print(f"Test file size: {size_mb}MB")
    print("=" * 60)

    # Create test file
    test_file = create_test_file(size_mb)

    try:
        # Upload test file
        upload_file(url, test_file)
    finally:
        # Cleanup
        if os.path.exists(test_file):
            os.remove(test_file)
            print(f"\nCleaned up test file: {test_file}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ['-h', '--help']:
        print("Usage: python3 test-upload.py [URL] [SIZE_MB]")
        print("\nArguments:")
        print("  URL      - Server URL (default: http://localhost:5000)")
        print("  SIZE_MB  - Test file size in MB (default: 100)")
        print("\nExamples:")
        print("  python3 test-upload.py")
        print("  python3 test-upload.py http://localhost:5000 50")
        print("  python3 test-upload.py https://upload.example.com 200")
        sys.exit(0)

    main()
