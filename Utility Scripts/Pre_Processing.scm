;; Define a function to create a line
(define (create-line name x0 y0 x1 y1)
  (let ((command (string-append "/surface/line-surface\n"
                                name "\n"
                                (number->string x0) "\n"
                                (number->string y0) "\n"
                                (number->string x1) "\n"
                                (number->string y1) "\n")))
    ; Display command for debugging
    (display (string-append "Executing command:\n" command))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to create specific angular momentum
(define (create-angular)
  (let ((command (string-append "/define/custom-field-functions/define\n"
                                "\"angular-momentum\"\n"
                                "radial_coordinate * swirl_velocity\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)

;; Parameters for the line creation
(define start-y 0)              ; y-coordinate of start point
(define end-y 0.035)            ; y-coordinate of end point
(define num-lines-pre 9)        ; Number of lines to create in the pre-chamber
(define x-spacing-pre 0.002)    ; Spacing between lines along the x-axis
(define x-init-pre 0.0022)      ; Initial x-coordinate
(define num-lines-grain 28)     ; Number of lines to create in the grain
(define x-spacing-grain 0.035)  ; Spacing between lines along the x-axis
(define x-init-grain 0.0222)    ; Initial x-coordinate
(define num-lines-post 10)      ; Number of lines to create in the post-chamber
(define x-spacing-post 0.007)   ; Spacing between lines along the x-axis
(define x-init-post 0.9922)     ; Initial x-coordinate

;; Extracting mass flow rate through the throat
(define x-throat 1.08) ; x-coordinate of the throat
(define line-name (format #f "throat"))
(create-line line-name x-throat start-y x-throat end-y)

;; Loop to create multiple lines in the pre-chamber
(do ((i 0 (+ i 1)))
    ((>= i num-lines-pre) 'done)
  ; Compute line name and x-position
  (define line-name (format #f "line-~a" i))
  (define x-pos (+ (* i x-spacing-pre) x-init-pre))  ; Compute x position for each line based on spacing
  
  ; Create the line
  (create-line line-name x-pos start-y x-pos end-y)
  
)
;; Loop to create multiple lines in the grain
(do ((i 0 (+ i 1)))
    ((>= i num-lines-grain) 'done)
  ; Compute line name and x-position
  (define num-lines (+ i num-lines-pre))
  (define line-name (format #f "line-~a" num-lines))
  (define x-pos (+ (* i x-spacing-grain) x-init-grain))  ; Compute x position for each line based on spacing
  
  ; Create the line
  (create-line line-name x-pos start-y x-pos end-y)
  
)
;; Loop to create multiple lines in the post-chamber
(do ((i 0 (+ i 1)))
    ((>= i num-lines-post) 'done)
  ; Compute line name and x-position
  (define num-lines (+ (+ i num-lines-grain) num-lines-pre))
  (define line-name (format #f "line-~a" num-lines))
  (define x-pos (+ (* i x-spacing-post) x-init-post))  ; Compute x position for each line based on spacing
  
  ; Create the line
  (create-line line-name x-pos start-y x-pos end-y)
  
)
;; Create specific angular momentum as a field variable
(create-angular)