; Define a function to compute the pdf table
(define (pdf-compute p)
  (let ((command (string-append "/define/models/species/non-premixed-combustion\n"
                                "yes\n"
                                "yes\n"
                                "\n"
                                "\n"
                                (number->string p) "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\"c2h4\"\n"
                                "1\n"
                                "0\n"
                                "\"o2\"\n"
                                "0\n"
                                "1\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "\n"
                                "table.pdf\n"
                                "\n"
                                "OK\n")))
    ; Display command for debugging
    (display (string-append "Executing command:\n" command))
    ; Execute the command
    (ti-menu-load-string command)
  )
)

;; Reading the maximum pressure in the domain
; Executing a custom UDF to extract maximum pressure
(ti-menu-load-string "/define/user-defined/execute-on-demand \"max_pressure_file::libudf\"")
; Define the name of the file to open
(define tmpfile "pmax_udf.txt")

; Opening and reading the file value
(define prova (open-input-file tmpfile))
(define line (read-line prova))
(close-input-port prova)

; Converting the output the wanted format
(define p (string->number line))
(define p (* p 100000.0))

; Updating the pdf table
(pdf-compute p)