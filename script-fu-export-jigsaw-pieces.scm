; MIT License
;
; Copyright (c) 2023 BeXXsoR
;
; Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


; This script adds a jigsaw pattern to the current image and exports all jigsaw pieces as individul files.
; PREREQUISITES: 
; - The image must be scalable to 1728x1296, i.e. it must have a 4:3 ratio.
; - Currently only row and column ratios of 6x8, 9x12, 12x16 and 15x20 are supported. If you want other ratios, extend the following variables: VALID_PIECE_RATIOS, supportedRows, imageSizes, clipSizes, borderSizes
; INPUTS:
; - Save Directory: Directory to save the individual jigsaw pieces to.
; - Num Rows: Number of rows of the jigsaw pattern
; - Num Columns: Number of columns of the jigsaw pattern
; OUTPUT:
; - One .png image per jigsaw piece. Each file is named "{filePrefix}_{i}_{j}.png", where {filePrefix} matches the name of the upmost folder of the save directory, and {i} and {j} are the row and column of the respective piece
; REMARKS:
; - The parts of the new images that don't belong to the actual jigsaw piece are transparent.
; - All pieces share a common size, no matter if a piece has all holes or all clips or something in between. The core of the piece will always be in the center; if it has a clip at a side, that side is untouched, but if it has a hole at a side, a transparent part is added to that side that matches the size of the clip.

(define (script-fu-export-jigsaw-pieces 
			inImage
			inLayer
			inDir 
			inNumRows
			inNumColumns) 
	; Initial checks
	(let* (
		(VALID_PIECE_RATIOS (list '(6 8) '(9 12) '(12 16) '(15 20)))
		)
		(if (member (list inNumRows inNumColumns) VALID_PIECE_RATIOS) () (error "Invalid ratio of rows/columns. Supported ratios are 6x8, 9x12, 12x16 and 15x20."))
		(if (equal? (/ (car (gimp-image-width inImage)) (car (gimp-image-height inImage))) (/ 4.0 3.0)) () (error "Can't scale picture to 1728x1296. Please scale manually and restart the script."))
	)
	; Let's go!
	(let* (
		(WHITE '(255 255 255))
		(i 0)
		(j 0)
		(pathchar (if (equal? (substring gimp-dir 0 1) "/") "/" "\\"))
		(filePrefix (string-append (car (reverse (strbreakup inDir pathchar))) "_"))
		(fileName "")
		(fileSuffix ".png")
		(imageWidth 0)
		(imageHeight 0)
		(pieceWidth 0)
		(pieceHeight 0)
		(pieceWidthHalf 0)
		(pieceHeightHalf 0)
		(copiedImage 0)
		(jigsawLayer 0)
		(contentLayer 0)
		(curImage 0)
		(curLayer 0)
		(supportedRows '(6 9 12 15))
		(imageSizes #(322 214 160 126))
		(clipSizes #(53 35 26 20))	; formula: clipSizes[i] = (imageSizes[i] - 1296 / inNumRows) / 2
		(borderSizes #(64 42 31 24)) ; formula: borderSizes[i] = 1.2 * clipSizes[i]
		(sizeIndex (- (length supportedRows) (length (member inNumRows supportedRows))))
		(curImageSize (vector-ref imageSizes sizeIndex))
		(curClipSize (vector-ref clipSizes sizeIndex))
		(curDistBorder (vector-ref borderSizes sizeIndex))
		(alphaTop 255)
		(alphaLeft 255)
		)
	; Prepare image and variables
	(set! copiedImage (car(gimp-image-duplicate inImage)))
	(set! contentLayer (vector-ref (cadr (gimp-image-get-layers copiedImage)) 0))
	(gimp-layer-scale contentLayer 1728 1296 FALSE)
	(plug-in-autocrop RUN-NONINTERACTIVE copiedImage contentLayer)
	(gimp-layer-add-alpha contentLayer)
	(set! imageWidth (car (gimp-image-width copiedImage)))
	(set! imageHeight (car (gimp-image-height copiedImage)))
	(set! pieceWidth (/ imageWidth inNumColumns))
	(set! pieceHeight (/ imageHeight inNumRows))
	(set! pieceWidthHalf (/ pieceWidth 2))
	(set! pieceHeightHalf (/ pieceHeight 2))
	; Prepare the jigsaw layer
	(set! jigsawLayer (car (gimp-layer-new copiedImage imageWidth imageHeight RGB-IMAGE "SolidBlack" 100 LAYER-MODE-NORMAL)))
	(gimp-image-insert-layer copiedImage jigsawLayer 0 0)
	(plug-in-jigsaw RUN-NONINTERACTIVE copiedImage jigsawLayer inNumColumns inNumRows 0 5 0)
	; Loop over the jigsaw pieces
    (while (< i inNumRows)
		(set! j 0)
		(while (< j inNumColumns)
			; Copy the jigsaw piece at row i and column j into a new image
			(gimp-selection-none copiedImage)
			(gimp-image-select-contiguous-color copiedImage CHANNEL-OP-REPLACE jigsawLayer (+ pieceWidthHalf (* j pieceWidth)) (+ pieceHeightHalf (* i pieceHeight)))
			(gimp-edit-copy contentLayer)
			(set! curImage (car(gimp-edit-paste-as-new-image)))
			(set! curLayer (vector-ref (cadr (gimp-image-get-layers curImage)) 0))
			; Resize the piece image to a common size. For that, get the alpha values at top/ left to check for transparency (transparency there indicates that there's a clipper at top/ left)
			(set! alphaTop (vector-ref (cadr(gimp-drawable-get-pixel curLayer curDistBorder 10)) 3))
			(set! alphaLeft (vector-ref (cadr(gimp-drawable-get-pixel curLayer 10 curDistBorder)) 3))
			(gimp-layer-resize curLayer curImageSize curImageSize (if (equal? alphaLeft 0) 0 curClipSize) (if (equal? alphaTop 0) 0 curClipSize))
			(gimp-image-resize-to-layers curImage)
			; Save the image
			(set! fileName (string-append inDir pathchar filePrefix (number->string i) "_" (number->string j) fileSuffix))
			(gimp-file-save RUN-NONINTERACTIVE curImage curLayer fileName fileName)
			; Cleanup
			(gimp-image-delete curImage)
			(set! j (+ j 1))
		)
		(set! i (+ i 1))
	)
	; Cleanup
	(gimp-image-delete copiedImage)
	)
) 

(script-fu-register 
	 "script-fu-export-jigsaw-pieces" 
	 "<Image>/Tools/Export Jigsaw Pieces" 
	 "Cut the image into a jigsaw pattern and export all jigsaw pieces as individual files" 
	 "Thomas Schneider" 
	 "Thomas Schneider" 
	 "2023/04/04" 
	 ""
	 SF-IMAGE	    "Image" 0
	 SF-DRAWABLE	"Layer" 0
	 SF-DIRNAME     "Save Directory" ""
	 SF-VALUE		"Num Rows" "6"
	 SF-VALUE		"Num Columns" "8"
 )
