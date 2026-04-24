(in-package :cl-mpm/examples/collapse)

(defparameter *sim* nil)
(defparameter *run-sim* t)
(defparameter *t* 0)
(defparameter *sim-step* 0)
(defparameter *refine* 0.5)
(let ((refine (uiop:getenv "REFINE")))
  (when refine
    (setf *refine* (parse-integer (uiop:getenv "REFINE")))  
    ))

(defparameter *solver* (let ((var (uiop:getenv "SOLVER"))) (if var var "DR")))
(defparameter *solver-hash* (serapeum:dict "DR" 'cl-mpm/dynamic-relaxation::mpm-sim-quasi-static "IMPLICIT" 'cl-mpm/implicit::mpm-sim-implicit))


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
              (dt (float (/ (- end start) (* iterations units)) 0d0))
              )
         (format t "Total time: ~f ~%" (/ (- end start) units)) (format t "Time per iteration: ~f~%" (/ (- end start) (* iterations units)))
         (if (> dt 0)
             (format t "Throughput: ~f - MPs throughput: ~E~%" (/ 1 dt) (/ (length (cl-mpm:sim-mps *sim*)) dt))
             (format t "Bad sample - 0 time taken~%")
             )
         dt))))

(declaim (notinline test))
(defun test ()
  (setup
    :refine *refine*
    :mps 3)
  (change-class *sim* (gethash *solver* *solver-hash*))
  (time-form (cl-mpm::update-sim *sim*) 1)
  (let ((dt-test 0d0))
    (setf dt-test
      (time-form
       (cl-mpm::update-sim *sim*)
       10))
  )
  )
(format t "Testing thread count: ~D ~%" *threads*)
(setf lparallel:*kernel* (lparallel:make-kernel *threads* :name "custom-kernel"))
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
