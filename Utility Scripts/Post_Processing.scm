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
(define (contour name-contour field iter pos)
  (define file-name (format #f "~a_~a-iter_~a.png" field pos iter))
  (let ((command (string-append "/display/objects\n"
                                "edit\n"
                                name-contour "\n"
                                "field\n"
                                field "\n"
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
;; Define a function to create a pathlines contour
(define (pathline iter pos)
  (define file-name (format #f "pathlines_~a-iter_~a.png" pos iter))
  (let ((command (string-append "/display/objects\n"
                                "edit\n"
                                "pathlines-1\n"
                                "color-map\n"
                                "visible\n"
                                "no\n"
                                "quit\n"
                                "quit\n"
                                "display\n"
                                "pathlines-1\n"
                                "quit\n"
                                "display/save-picture\n"
                                file-name "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to export the target variable on a line
(define (export-line-data line-name variable iter x y)
  (define file-name (format #f "convergenza-~a-~a-iter_~a" line-name variable iter))
  (let ((command (string-append "/plot/plot\n"
                                "\n"
                                file-name "\n"
                                "yes\n"
                                "\n"
                                "\n"
                                variable "\n"
                                "yes\n"
                                (number->string x) "\n"
                                (number->string y) "\n"
                                line-name "\n"
                                "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to extract the mean value of the target variable on a surface
(define (export-values meaner surface variable iter)
  (define file-name (format #f "convergenza-scalare-~a-~a-iter_~a" surface variable iter))
  (let ((command (string-append "/report/surface-integrals\n"
                                meaner "\n"
                                surface "\n"
                                "\n"
                                variable "\n"
                                "yes\n"
                                file-name "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to extract the mass flow rate through a surface
(define (export-mass-flow surface iter)
  (define file-name (format #f "convergenza-mass-flow-~a-iter_~a" surface iter))
  (let ((command (string-append "/report/surface-integrals\n"
                                "mass-flow-rate\n"
                                surface "\n"
                                "\n"
                                "yes\n"
                                file-name "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)
;; Define a function to compute a flux through a surface
(define (compute-quantity plane-name variable iter)
  (define file-name (format #f "swirlnumber-~a-~a-iter_~a.srp" plane-name variable iter))
  (let ((command (string-append "/report/surface-integrals\n"
                                "flow-rate\n"
                                plane-name "\n"
                                "\n"
                                variable "\n"
                                "yes\n"
                                file-name "\n")))
    ; Execute the command
    (ti-menu-load-string command)
  )
)

;; Parameters for the data extraction
; Defining the number of lines created
(define num-lines-pre 9)
(define num-lines-grain 28)
(define num-lines-post 10)
(define num-lines (+ (+ num-lines-pre num-lines-grain) num-lines-post))
; Defining name of contours previously created in Fluent
(define base "contour-1")
(define positive "contour-2")
; Defining variable to be outputed in plot or contours
(define ax-vel "axial-velocity")
(define tan-vel "swirl-velocity")
(define ang-mom "angular-momentum")
(define temp "temperature")
(define water "h2o")
(define mach "mach-number")
(define var1 "udm-0")
(define var2 "udm-1")
(define var3 "udm-2")
(define var4 "udm-3")
(define var5 "y-plus")
(define var6 "wall-shear")
; Defining lines where extract data
(define line1 "grain")
(define line2 "pre")
(define line3 "post")
(define line4 "inlet")
(define line5 "outlet")
(define line6 "throat")
;(define line7 "inlet_swirl")
; Defining lines direction vector
(define x 1)
(define y 0)
; Defining the type of averaging to compute
(define meaner "area-weighted-avg")
; Recovering the current iteration to include in the output file name
(define iter (get-current-iteration))

;; Creating Contours and Extracting data on lines and surfaces
; Contours of the whole engine
(whole-camera)
(define pos "default")
(contour positive ax-vel iter pos)
(contour base temp iter pos)
(contour base water iter pos)
(pathline iter pos)
; Contours of the injector zone
(injector-camera)
(define pos "inj")
(contour positive ax-vel iter pos)
(contour base mach iter pos)
(contour base tan-vel iter pos)
(pathline iter pos)
; Extracting values of target variables on target lines in the axial direction
(export-line-data line1 var1 iter x y)
(export-line-data line1 var2 iter x y)
(export-line-data line1 var3 iter x y)
(export-line-data line1 var4 iter x y)
(export-line-data line1 var5 iter x y)
(export-line-data line1 var6 iter x y)
(export-line-data line2 var5 iter x y)
(export-line-data line2 var6 iter x y)
(export-line-data line3 var5 iter x y)
(export-line-data line3 var6 iter x y)
; Extracting mean values of target variables on target lines
(export-values meaner line1 var3 iter)
(export-values meaner line1 var1 iter)
; Extracting mass flow rates through target lines
(export-mass-flow line4 iter)
(export-mass-flow line5 iter)
(export-mass-flow line6 iter)
;(export-mass-flow line7 iter)


;; Extracting quantities necessary to compute Swirl Number
(define x 0)
(define y 1)
;; Loop to export data on lines
(do ((i 0 (+ i 1)))
    ((>= i num-lines) 'done)
  ; Recover line name
  (define line-name (format #f "line-~a" i))

  ; Extract axial velocity on the line
  (export-line-data line-name ax-vel iter x y)
  ; Extract swirl velocity on the line
  (export-line-data line-name tan-vel iter x y)
  ; Extract temperature on the line
  (export-line-data line-name temp iter x y)

  ; Compute angular momentum flux
  (compute-quantity line-name ang-mom iter)
  ; Compute axial momentum flux
  (compute-quantity line-name ax-vel iter)
  
)