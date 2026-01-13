; Define a function to initialize the pdf table
(define (pdf-initialize)
  (let ((command (string-append "/define/models/species/non-premixed-combustion\n"
                                "\n"
                                "\n"
                                "\n"
                                "table.pdf\n"
                                "\n")))
    ; Display command for debugging
    (display (string-append "Executing command:\n" command))
    ; Execute the command
    (ti-menu-load-string command)
  )
)

(pdf-initialize)