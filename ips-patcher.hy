#!/usr/bin/env hy
(import sys [argv stderr])

(defn load-rom [path]
  """
  Read the ROM file contents and return them as an array of ints (the numeric
  values of its bytes)
  """
  (setv file (open path "r+b")
        rom (list (.read file)))
  (.close file)
  (return rom))

(defn write-rom [data path]
  """
  Take the ROM data in the format dumped by `load-rom` then write it to a file
  """
  (setv file (open path "w+b"))
  (.write file (bytes data))
  (.close file))

(defn load-ips [path]
  """
  Loads an IPS file, parses it, then returns a list with all the IPS records
  parsed
  """
  (setv file (open path "r+b")
        patches [])
  (if (!= (.read file 5) b"PATCH")
    (do (print "Valid IPS header not found, quitting" :file stderr)
        (quit 1)))
  (while True
    (.append patches [])
    (. patches [-1] (append (.from-bytes int (.read file 3) "big"))) ;; Read the offset
    ;; check if it reached the EOF footer, and if yes clean up and finish
    ;; parsing
    (if (= (get patches -1 0) 4542278)
      (do
        (.pop patches)
        (break)))
    (. patches [-1] (append (.from-bytes int (.read file 2) "big"))) ;; read the size
    (if (!= (get patches -1 1) 0)                        ;; check if the size is 0
      (. patches [-1] (append (list (.read file (get patches -1 1))))) ;; if the size is >0 then assume normal patch encoding
      (do                                        ;; otherwise assume RLE encoding and read the RLE size
          (. patches [-1] (append (.from-bytes int (.read file 2) "big")))
          (. patches [-1] (append (.from-bytes int (.read file 1) "big"))))))
  (.close file)
  (return patches))

(defn apply-patches [rom patches]
  (for [patch patches]
    (if (= (get patch 1) 0)
      (setv (get rom (slice (get patch 0) (+ (get patch 0) (get patch 2))))
            (lfor byte (range (get patch 2)) (get patch 3)))
      (setv (get rom (slice (get patch 0) (+ (get patch 0) (get patch 1))))
            (get patch 2))))
  (return rom))

(defn main []
  (if (not-in (len argv) [3 4])
    (do (print "Please specify a ROM file, an IPS file, and optionally the output file" :file stderr)
        (print f"{(get argv 0)} <path/to/rom> <path/to/ips> [<path/to/output>]" :file stderr)
        (quit 1)))
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

(if (= __name__ "__main__")
  (main))
