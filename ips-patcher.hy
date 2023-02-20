#!/usr/bin/env hy
(import sys [argv stderr])

(setv EMPTY-RECORD {"offset" None
                    "size" None
                    "RLE" False ;; Default assumption is that all records are not RLE
                    "data" None})

(defn load-rom [path]
  """
  Read the ROM file contents and return them as an array of ints (the numeric
  values of its bytes)
  """
  (with [rom (open path "r+b")]
    (return (list (.read rom)))))

(defn write-rom [data path]
  """
  Take the ROM data in the format dumped by `load-rom` then write it to a file
  """
  (with [file (open path "w+b")]
    (.write file (bytes data))))

(defn load-ips [path]
  """
  Loads an IPS file, parses it, then returns a list with all the IPS records
  parsed as dictionaries in the format of `EMPTY-RECORD`
  """
  (setv file (open path "r+b")
        patches [])

  ;; Check if there's a valid header, quit if there isn't
  (when (!= (.read file 5) b"PATCH")
    (print "Valid IPS header not found, quitting" :file stderr)
    (quit 1))

  (while True
    (.append patches (.copy EMPTY-RECORD))
    ;; Read the offset
    (setv (get patches -1 "offset") (.from-bytes int (.read file 3) "big"))

    ;; Check if the EOF marker was reached and quit if so
    (when (= (get patches -1 "offset") 4542278)
      (.pop patches)
      (break))

    ;; read the size
    (setv (get patches -1 "size") (.from-bytes int (.read file 2) "big"))
    (if (= (get patches -1 "size") 0)
      ;; a size of 0 signals an RLE encoded record which has to be handled
      ;; differently, which means reading an RLE size then a single data byte
      (do
        (setv (get patches -1 "RLE") True
              (get patches -1 "size") (.from-bytes int (.read file 2) "big")
              (get patches -1 "data") (.from-bytes int (.read file 1) "big")))
      ;; and if the regular size is non-0 that's a regular record, meaning you
      ;; just read `size` number of bytes
      (setv (get patches -1 "data") (list (.read file (get patches -1 "size"))))))

  (.close file)
  (return patches))

(defn apply-patches [rom patches]
  """
  Apply the list of patches to the given ROM
  """
  (for [patch patches]
    ;; Regular and RLE-encoded records need to be applied differently.
    ;; - With a regular record you just overrite the data starting at offset
    ;;   until you reach Offset + Size (as that's where the data ends).
    ;; - With an RLE record, you set all bytes from Offset to Offset + Size
    ;;   to the data byte
    (setv (get rom (slice (get patch "offset") (+ (get patch "offset") (get patch "size"))))
          (if (get patch "RLE")
            (lfor byte (range (get patch "size")) (get patch "data"))
            (get patch "data"))))
  (return rom))

(defn main []
  (when (not-in (len argv) [3 4])
    (print "Please specify a ROM file, an IPS file, and optionally the output file" :file stderr)
    (print f"{(get argv 0)} <path/to/rom> <path/to/ips> [<path/to/output>]" :file stderr)
    (quit 1))

  (write-rom
    (apply-patches
      (load-rom (get argv 1))
      (load-ips (get argv 2)))

    (if (= (len argv) 4)
      (get argv 3)
      (+ (get argv 1 (slice (.rfind (get argv 1) ".")))
         " - "
         (get argv 2 (slice (.rfind (get argv 2) ".")))
         (get argv 1 (slice (.rfind (get argv 1) ".") None))))))

(when (= __name__ "__main__")
  (main))
