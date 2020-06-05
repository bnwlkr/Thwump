import subprocess
import os
import argparse
import fnmatch
import pathlib
import sys

def main():
    parser = argparse.ArgumentParser(description="Combine mp3 and png images into thwump iMessage thumbnails")
    parser.add_argument("--pngs", help="directory containing pngs to convert")
    parser.add_argument("--mp3s", help="directory of mp3 clips")
    parser.add_argument("--out", help="output directory")
    args = parser.parse_args()

    # create the output dir if necessary
    pathlib.Path(args.out).mkdir(parents=True, exist_ok=True)

    # replace transparent backgrounds and resize
    for png_file in pathlib.Path(args.pngs).glob("*.png"):
        png_output_path = pathlib.Path(args.out, png_file.name)
        if subprocess.call(f"convert -resize 150x150 -background '#e8e8e8' -flatten {png_file} {png_output_path}", shell=True) != 0:
            print("Failed to process png, exiting")
            return 1
        mp3_file = pathlib.Path(args.mp3s, f"{png_file.stem}.mp3")
        if not mp3_file.is_file():
            print(f"Couldn't find mp3 for {png_file.name}")
            continue
        mp4_output_path = pathlib.Path(args.out, f"{png_file.stem}.mp4")

        if subprocess.call(f"ffmpeg -i {png_output_path} -i {mp3_file} -vcodec libx264 -pix_fmt yuv420p -c:a aac {mp4_output_path}", shell=True) != 0:
            print(f"Failed to create mp4 for {png_file.stem}")
            return 1
        png_output_path.unlink()


if __name__=="__main__":
    sys.exit(main())


