;; Define a function to move the camera to fit the whole engine
(define (whole-camera)
  (let ((command (string-append "/display/views\n"
                                "default\n"
                                "camera\n"
                                "zoom\n"
                                "3\n"
                                "quit\n"
                                "quit\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to move the camera to fit the injector zone
(define (injector-camera)
  (let ((command (string-append "/display/views/camera\n"
                                "pan\n"
                                "10\n"
                                "0\n"
                                "zoom\n"
                                "10\n"
                                "quit\n"
                                "quit\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to create a target field contour
(define (contour name-contour field iter pos massimo minimo)
  (define file-name (format #f "~a_~a-iter_~a.png" field pos iter))
  (let ((command (string-append "/display/objects\n"
                                "edit\n"
                                name-contour "\n"
                                "field\n"
                                field "\n"
                                "color-map/size\n"
                                "20\n"
                                "quit\n"
                                "range\n"
                                "auto-range-off\n"
                                "maximum\n"
                                (number->string massimo) "\n"
                                "minimum\n"
                                (number->string minimo) "\n"
                                "quit\n"
                                "quit\n"
                                "display\n"
                                name-contour "\n"
                                "quit\n"
                                "display/save-picture\n"
                                file-name "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)

;; Parameters for the contour creation
; Defining name of contours previously created in Fluent
(define base "contour-1")
(define positive "contour-2")
; Defining variable to be outputed in plot or contours
(define ax-vel "axial-velocity")
(define tan-vel "swirl-velocity")
(define temp "temperature")
(define water "h2o")
(define mach "mach-number")
; Defining ranges for each variable defined
(define ax-vel-max 250)
(define ax-vel-min 0)
(define tan-vel-max 200)
(define tan-vel-min 0)
(define temp-max 3610)
(define temp-min 200)
(define water-max 0.289)
(define water-min 0)
(define mach-max 1)
(define mach-min 0)
; Recovering the current iteration to include in the output file name
(define iter (get-current-iteration))

;; Creating Contours and Extracting data on lines and surfaces
; Contours of the whole engine
(whole-camera)
(define pos "default")
(contour positive ax-vel iter pos ax-vel-max ax-vel-min)
(contour base temp iter pos temp-max temp-min)
(contour base water iter pos water-max water-min)
; Contours of the injector zone
(injector-camera)
(define pos "inj")
(contour positive ax-vel iter pos ax-vel-max ax-vel-min)
(contour base mach iter pos mach-max mach-min)
(contour base tan-vel iter pos tan-vel-max tan-vel-min)