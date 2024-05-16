;; (sb-ext:restrict-compiler-policy 'speed  3 3)
;; (sb-ext:restrict-compiler-policy 'debug  0 0)
;; (sb-ext:restrict-compiler-policy 'safety 0 0)
(declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
(sb-ext:restrict-compiler-policy 'speed  3 3)
(sb-ext:restrict-compiler-policy 'debug  0 0)
(sb-ext:restrict-compiler-policy 'safety 0 0)
;; (setf *block-compile-default* t)
(ql:quickload :cl-mpm :silent t)
(ql:quickload :cl-mpm/damage :silent t)
(ql:quickload :cl-mpm/setup :silent t)
(ql:quickload :cl-mpm/output :silent t)
(ql:quickload :cl-mpm/particle :silent t)
(ql:quickload :cl-mpm/mesh :silent t)
(ql:quickload :cl-mpm/plotter :silent t)
(ql:quickload :lparallel :silent t)
(ql:quickload :vgplot :silent t)
(ql:quickload :swank.live)
;(format t "Force compiling~%")
;; (asdf:compile-system :cl-mpm :force t)
;; (asdf:compile-system :cl-mpm/setup :force t)
;; (asdf:compile-system :cl-mpm/particle :force t)
;; (asdf:compile-system :cl-mpm/mesh :force t)
;; (asdf:compile-system :cl-mpm/constitutive :force t)
;; (asdf:compile-system :cl-mpm/damage :force t)
;; (asdf:compile-system :cl-mpm/utils :force t)
;; (asdf:compile-system :cl-mpm/bc :force t)
;; (asdf:compile-system :cl-mpm/forces :force t)
;; (asdf:compile-system :cl-mpm/ext :force t)
;; (asdf:compile-system :cl-mpm/output :force t)
;; (asdf:compile-system :cl-mpm/fastmath :force t)
;(asdf:compile-system :cl-mpm/examples/joss :force t)
;; (require 'sb-sprof)
;(load #P"SYS:CONTRIB;sb-perf;export-syms.lisp")
;(sb-perf:write-perfmap)

;; (defun max-stress (mp)
;;   (magicl:tref (cl-mpm/particle:mp-stress mp) 1 0))

(defun setup-test-column (size block-size &optional (e-scale 1) (mp-scale 1))
  (let* ((sim (cl-mpm/setup::make-block
               (/ 1d0 e-scale)
               (mapcar (lambda (x) (* x e-scale)) size)
               ;:sim-type 'cl-mpm/damage::mpm-sim
               ))
         (h (cl-mpm/mesh:mesh-resolution (cl-mpm:sim-mesh sim)))
         (h-x (/ h 1d0))
         (h-y (/ h 1d0))
         (density 1d3)
         (elements (mapcar (lambda (s) (* e-scale (/ s 2))) size))
         )
    (declare (double-float h density))
    (progn
      (let ()
        (setf (cl-mpm:sim-mps sim)
              (cl-mpm/setup::make-mps-from-list
               (cl-mpm/setup::make-block-mps-list
                '(0 0 0)
                block-size
                (mapcar (lambda (e) (* e e-scale mp-scale)) block-size)
                density
                ;'cl-mpm/particle::particle-elastic-damage
                'cl-mpm/particle::particle-elastic
                ;'cl-mpm/particle::particle-vm
                :E 1d6
                :nu 0.3d0
                ;:rho 20d3
                :gravity -10.0d0
                :gravity-axis (cl-mpm/utils:vector-from-list '(0d0 0d0 1d0))
                ))))
      (setf (cl-mpm:sim-damping-factor sim) (* 1d-3 density))
      (setf (cl-mpm::sim-mass-scale sim) 1d0)
      (let ((dt-scale 1.0d0))
        (setf
         (cl-mpm:sim-dt sim)
         (* dt-scale h
            (sqrt (cl-mpm::sim-mass-scale sim))
            (sqrt (/ density (cl-mpm/particle::mp-p-modulus (aref (cl-mpm:sim-mps sim) 0)))))))

      (format t "Estimated dt ~F~%" (cl-mpm:sim-dt sim))
      (setf (cl-mpm:sim-bcs sim)
            (cl-mpm/bc::make-outside-bc-var (cl-mpm:sim-mesh sim)
                                            (lambda (i) (cl-mpm/bc::make-bc-fixed i '(0 nil nil)))
                                            (lambda (i) (cl-mpm/bc::make-bc-fixed i '(0 nil nil)))
                                            (lambda (i) (cl-mpm/bc::make-bc-fixed i '(nil 0 nil)))
                                            (lambda (i) (cl-mpm/bc::make-bc-fixed i '(nil 0 nil)))
                                            (lambda (i) (cl-mpm/bc::make-bc-fixed i '(nil nil 0)))
                                            (lambda (i) (cl-mpm/bc::make-bc-fixed i '(nil nil 0)))
                                           ))
      sim)))


(defparameter *sim* nil)
(defparameter *run-sim* t)
(defparameter *t* 0)
(defparameter *sim-step* 0)
(defparameter *refine* 0.5)
(let ((refine (uiop:getenv "REFINE")))
  (when refine
    (setf *refine* (parse-integer (uiop:getenv "REFINE")))  
    ))

(defun setup ()
  (defparameter *sim* (setup-test-column (list (* *refine* 8) 8 8) (list (* *refine* 8) 8 8) 1 2))
  ;; (defparameter *sim* (setup-test-column '(1 1 1) '(1 1 1) 1 1))
  (format t "MPs: ~D~%" (length (cl-mpm:sim-mps *sim*)))
  (defparameter *run-sim* t)
  (defparameter *t* 0)
  (defparameter *sim-step* 0))

(defun run-auto-strong ()
  (cl-mpm/output:save-vtk-mesh (merge-pathnames "output/mesh.vtk")
                          *sim*)
  (let* ((target-time 0.1d0)
         (dt (cl-mpm:sim-dt *sim*))
         (substeps (floor target-time dt)))
    (format t "Substeps ~D~%" substeps)
    (time (loop for steps from 0 to 40
                while *run-sim*
                do
                   (progn
                     (format t "Step ~d ~%" steps)
                     (cl-mpm/output:save-vtk (merge-pathnames (format nil "output/sim_~5,'0d.vtk" *sim-step*)) *sim*)
                     (time
                      (dotimes (i substeps)
                        (cl-mpm::update-sim *sim*)
                        (setf *t* (+ *t* (cl-mpm::sim-dt *sim*)))))
                     ;; (setf (cl-mpm:sim-damping-factor *sim*)
                     ;;       (* (cl-mpm:sim-damping-factor *sim*) (expt 1d-3 1/40)))

                     (incf *sim-step*)
                     ;; (plot *sim*)
                     ;(cl-mpm/plotter:simple-plot-3d *sim* :colour-func (lambda (mp) (cl-mpm/utils:get-stress (cl-mpm/particle::mp-stress mp) :xx)))
                     ;(swank.live:update-swank)
                     ))))
  (cl-mpm/output:save-vtk (merge-pathnames (format nil "output/sim_~5,'0d.vtk" *sim-step*)) *sim*))


(defparameter *threads* 1)
(let ((threads (uiop:getenv "OMP_NUM_THREADS")))
    (when threads
          (setf *threads* (parse-integer threads))))

;; (push (lambda ()
;;         (format t "Closing kernel~%")
;;         (lparallel:end-kernel))
;;       sb-ext:*exit-hooks*)
;(setup)
;(run)

(defmacro time-form (form it)
  `(progn
     (declaim (optimize speed))
     (let* ((iterations ,it)
            (start (get-internal-real-time)))
       (dotimes (i ,it)
         ,form)
       (let* ((end (get-internal-real-time))
              (units internal-time-units-per-second)
              (dt (/ (- end start) (* iterations units)))
              )
         (format t "Total time: ~f ~%" (/ (- end start) units)) (format t "Time per iteration: ~f~%" (/ (- end start) (* iterations units)))
         (if (> dt 0)
             (format t "Throughput: ~f~%" (/ 1 dt))
             (format t "Bad sample - 0 time taken~%")
             )
         dt))))

(declaim (notinline test))
(defun test ()
  (setup)
  (cl-mpm::update-sim *sim*)
  (time-form
   (cl-mpm::update-sim *sim*)
   100)
  )
;; (format t "Threads ~D~%" *threads*)
(format t "Testing thread count: ~D ~%" *threads*)
(setf lparallel:*kernel* (lparallel:make-kernel *threads* :name "custom-kernel"))
;; (cl-mpm::update-sim *sim*)
(test)
(test)
(test)
(lparallel:end-kernel)
(sb-ext:gc :full t)
;(let ((max-threads *threads*))
;  (loop for i from 0 to (round (log *threads* 2))
;        do
;           (progn
;             (format t "Testing thread count: ~D ~%" (expt 2 i))
;             (setf lparallel:*kernel* (lparallel:make-kernel (expt 2 i) :name "custom-kernel"))
;             (test)
;             (lparallel:end-kernel)
;             (sb-ext:gc :full t))))

;; (lparallel:end-kernel)
;; (sb-ext::exit)
;; (uiop:quit)


;; (declaim (optimize (debug 0) (safety 0) (speed 3)))
;; (defun test ()
;;     (let ((iters 10000000))
;;       (let ((a (cl-mpm/utils:vector-zeros)))
;;         (time
;;          (lparallel:pdotimes (i iters)
;;            (magicl:.+ a (cl-mpm/utils:vector-zeros) a))))
;;       (let ((a (make-array 2 :element-type 'double-float)))
;;         (time
;;          (lparallel:pdotimes (i iters)
;;            (let ((b (make-array 2 :element-type 'double-float)))
;;              (loop for i fixnum from 0 to 1
;;                    do (incf (aref a i) (aref b i))))
;;            )))))
