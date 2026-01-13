;; Define a function to create a line
(define (create-line name x0 y0 z0 x1 y1 z1) ; Se non funziona guarda line-surface
  (let ((command (string-append "/surface/line-surface\n"
                                name "\n"
                                (number->string x0) "\n"
                                (number->string y0) "\n"
                                (number->string z0) "\n"
                                (number->string x1) "\n"
                                (number->string y1) "\n"
                                (number->string z1) "\n")))
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
                                "radial_coordinate * tangential_velocity\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to create a plane
(define (create-plane plane-name x0)
  (let ((command (string-append "/surface/plane-surface\n"
                                plane-name "\n"
                                "yz-plane\n"
                                (number->string x0) "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)

;; Parameters for the line and plane creation
(define num-lines-pre 9)        ; Number of lines to create in the pre-chamber
(define x-spacing-pre 0.002)    ; Spacing between lines along the x-axis
(define x-init-pre 0.0022)      ; Initial x-coordinate
(define num-lines-grain 28)     ; Number of lines to create in the grain
(define x-spacing-grain 0.035)  ; Spacing between lines along the x-axis
(define x-init-grain 0.0222)    ; Initial x-coordinate
(define num-lines-post 10)      ; Number of lines to create in the post-chamber
(define x-spacing-post 0.007)   ; Spacing between lines along the x-axis
(define x-init-post 0.9922)     ; Initial x-coordinate
(define start-y 0)              ; y-coordinate of start point
(define end-y1 0.0280)          ; y-coordinate of vertical end point
(define end-y2 0.0259)          ; y-coordinate of middle end point
(define start-z 0)              ; z-coordinate of start point
(define end-z -0.0107)          ; z-coordinate of end point

;; Loop to create multiple lines and planes in the pre-chamber
(do ((i 0 (+ i 1)))
    ((>= i num-lines-pre) 'done)
  ; Compute line name and x-position
  (define num (* i 2))
  (define line-name (format #f "line-~a" num))
  (define plane-name (format #f "plane-~a" i))
  (define x-pos (+ (* i x-spacing-pre) x-init-pre))  ; Compute x position for each line based on spacing
  
  ; Create the vertical line
  (create-line line-name x-pos start-y start-z x-pos end-y1 start-z)
  ; Create the plane
  (create-plane plane-name x-pos)

  
  (define num (+ num 1))
  (define line-name (format #f "line-~a" num))
  ; Create the middle line
  (create-line line-name x-pos start-y start-z x-pos end-y2 end-z)
  
)
;; Loop to create multiple lines and planes in the grain
(do ((i 0 (+ i 1)))
    ((>= i num-lines-grain) 'done)
  ; Compute line name and x-position
  (define num (+ num-lines-pre (* i 2)))
  (define line-name (format #f "line-~a" num))
  (define plane-name (format #f "plane-~a" (+ i num-lines-pre)))
  (define x-pos (+ (* i x-spacing-grain) x-init-grain))  ; Compute x position for each line based on spacing
  
  ; Create the vertical line
  (create-line line-name x-pos start-y start-z x-pos end-y1 start-z)
  ; Create the plane
  (create-plane plane-name x-pos)

  
  (define num (+ num 1))
  (define line-name (format #f "line-~a" num))
  ; Create the middle line
  (create-line line-name x-pos start-y start-z x-pos end-y2 end-z)
  
)
;; Loop to create multiple lines and planes in the post-chamber
(do ((i 0 (+ i 1)))
    ((>= i num-lines-post) 'done)
  ; Compute line name and x-position
  (define num (+ num-lines-pre (+ num-lines-grain (* i 2))))
  (define line-name (format #f "line-~a" num))
  (define plane-name (format #f "plane-~a" (+ num-lines-pre (+ num-lines-grain i))))
  (define x-pos (+ (* i x-spacing-post) x-init-post))  ; Compute x position for each line based on spacing
  
  ; Create the vertical line
  (create-line line-name x-pos start-y start-z x-pos end-y1 start-z)
  ; Create the plane
  (create-plane plane-name x-pos)

  
  (define num (+ num 1))
  (define line-name (format #f "line-~a" num))
  ; Create the middle line
  (create-line line-name x-pos start-y start-z x-pos end-y2 end-z)
  
)
;; Create specific angular momentum as a field variable
(create-angular)