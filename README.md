# GIMP Export Jigsaw Pieces
This script adds a jigsaw pattern to the current image and exports all jigsaw pieces as individul files.

## How to use
The script is written for GIMP (GNU Image Manipulation Program, a free and open source image editor). You don't need any GIMP knowledge though, just follow these steps:
1) Donwload GIMP for your system from https://www.gimp.org/downloads/ and install it.
2) Copy the *script-fu-export-jigsaw-pieces.scm* file from this repository and paste it into the subfolder *share/gimp/2.0/scripts/* of the directory where you installed GIMP to.
3) Start GIMP and open the image you want to use (*File->Open* via the Gimp Menu)
4) Via the GIMP menu, go for *Filters->Script-Fu->Refresh Scripts*
5) Start the script via *Tools->Export Jigsaw Pieces*

## Prerequisites
- The image must be scalable to 1728x1296, i.e. it must have a 4:3 ratio.
- Currently only row and column ratios of 6x8, 9x12, 12x16 and 15x20 are supported. If you want other ratios, extend the following variables in the script: VALID_PIECE_RATIOS, supportedRows, imageSizes, clipSizes, borderSizes.

## Inputs
- Save Directory: Directory to save the individual jigsaw pieces to
- Num Rows: Number of rows of the jigsaw pattern
- Num Columns: Number of columns of the jigsaw pattern

## Outputs
- One .png image per jigsaw piece. Each file is named *filePrefix\_i\_j.png*, where *filePrefix* matches the name of the upmost folder of the save directory, and *i* and *j* are the row and column of the respective piece.

## Remarks
- The parts of the new images that don't belong to the actual jigsaw piece are transparent.
- All pieces share a common size, no matter whether a piece has all holes or all clips or something in between. The core of the piece will always be in the center; if it has a clip at a side, that side is untouched, but if it has a hole, a transparent part is added to that side that matches the size of the clip.

## Troubleshooting
- There's no option *Tools->Export Jigsaw Pieces*: Make sure you've copied the *script-fu-export-jigsaw-pieces.scm* file into the *share/gimp/2.0/scripts/* subfolder of your GIMP directory. Then try *Filters->Script-Fu->Refresh Scripts* again.
- Error message "Invalid ratio of rows/columns. Supported ratios are 6x8, 9x12, 12x16 and 15x20.": Make sure you select row and column numbers that match one of the supported ratios.
- Error message "Can't scale picture to 1728x1296. Please scale manually and restart the script.": Your picture is not in a 4:3 format. To fix that, try one of the following options:
  - If your picture is in portrait instead of landscape mode, rotate it by 90 degrees (*Image->Transform->Rotate 90° clockwise*) and restart the script.
  - If your picture is indeed not in 4:3 format, first scale it so that either the width is 1728 and the height is greater than 1296, or the height is 1296 and the width is greater than 1728, via Gimp-menu *Image->Scale Image*. Then use *Layer->Layer Boundary Size*, with which you can cut off the protruded part by setting the not yet fitting dimension to 1728 resp. 1296. After that, restart the script.