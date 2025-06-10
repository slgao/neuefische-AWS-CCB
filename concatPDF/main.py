#! /usr/bin/env python
# coding=utf-8
# ================================================================
#   Copyright (C) 2025 * Ltd. All rights reserved.
#
#   Editor      : EMACS
#   File name   : concatPDF.py
#   Author      : slgao
#   Created date: Thu May 22 2025 17:53:07
#   Description :
#
# ================================================================
import os
from pypdf import PdfReader, PdfWriter
from pathlib import Path


def find_pdfs_in_folder(folder_path):
    pdf_files = []
    for dirpath, _, filenames in os.walk(folder_path):
        for file in sorted(filenames):  # Alphabetical order
            if file.lower().endswith(".pdf"):
                pdf_files.append(os.path.join(dirpath, file))
    return pdf_files


def merge_pdfs_with_writer(folders, output_file):
    writer = PdfWriter()
    total_files = 0

    for folder in folders:
        pdfs = find_pdfs_in_folder(folder)
        if not pdfs:
            print(f"⚠️ No PDFs found in: {folder}")
            continue

        print(f"🔍 Found {len(pdfs)} PDF(s) in {folder}")
        for pdf_path in pdfs:
            try:
                reader = PdfReader(pdf_path)
                for page in reader.pages:
                    writer.add_page(page)
                print(f"✅ Added: {pdf_path}")
                total_files += 1
            except Exception as e:
                print(f"❌ Failed to add {pdf_path}: {e}")

    if total_files > 0:
        with open(output_file, "wb") as f_out:
            writer.write(f_out)
        print(f"\n🎉 Successfully merged {total_files} PDF(s) into: {output_file}")
    else:
        print("❌ No PDFs were merged.")


if __name__ == "__main__":
    slides_folder = f"{Path.home()}/neuefische_training/AWS_cloud_computing/slides"
    chapters = [
        "CloudFoundations",
        "Linux",
        "Networking",
        "Security",
        "Databases",
        "PythonProgramming",
    ]  # order matters
    # Specify your folders here, in the order you want them processed
    folders_to_merge = [Path(f"{slides_folder}/{c}/").as_posix() for c in chapters]
    print(folders_to_merge[0])
    output_filename = "merged.pdf"
    output_path = Path(slides_folder, output_filename)
    merge_pdfs_with_writer(folders_to_merge, output_path.as_posix())
