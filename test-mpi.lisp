;(ql:quickload :cl-mpm/examples/collapse)
;(ql:quickload :cl-mpm/implicit)
;(ql:quickload :serapeum)
(in-package :cl-mpm/examples/collapse)

(defparameter *sim* nil)
(defparameter *run-sim* t)
(defparameter *t* 0)
(defparameter *sim-step* 0)

(defparameter *name* (let ((var (uiop:getenv "NAME"))) (if var var "standard")))
(defparameter *refine* (let ((var (uiop:getenv "REFINE"))) (parse-float:parse-float (if var var "1"))))
(defparameter *threads* (let ((var (uiop:getenv "OMP_NUM_THREADS"))) (parse-integer (if var var "0"))))
(defparameter *solver* (let ((var (uiop:getenv "SOLVER"))) (if var var "DR")))
(defparameter *solver-hash* (serapeum:dict "DR" 'cl-mpm/dynamic-relaxation::mpm-sim-quasi-static "IMPLICIT" 'cl-mpm/implicit::mpm-sim-implicit))
(setf lparallel:*kernel* (lparallel:make-kernel *threads* :name "custom-kernel"))


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


(defun setup-domain-decomp (sim)
  (setf cl-mpm/mpi::*prune-nodes* nil)
  (when (= (cl-mpi:mpi-comm-rank) 0)
    (format t "Starting domain decompose~%") )
  (setf (cl-mpm/mpi::mpm-sim-mpi-domain-count sim)
	    (list (floor (cl-mpi:mpi-comm-size)) 1 1))
  (cl-mpm/mpi::domain-decompose sim)
  (cl-mpm/mpi::load-balance-algo sim :dims '(:x :y))
  (when (= (cl-mpi:mpi-comm-rank) 0)
    (format t "Ending domain decompose~%")))

(declaim (notinline test))
(defun test ()
  (setup
    :refine (round *refine*)
    :mps 3)
  (change-class *sim* 'cl-mpm/dynamic-relaxation::mpm-sim-quasi-static-mpi)
  (setup-domain-decomp *sim*)
  (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) nil
      (cl-mpm::sim-ghost-factor *sim*) nil
      (cl-mpm::sim-enable-fbar *sim*) nil)
  ;(setf (cl-mpm/dynamic-relaxation::sim-mass-update-count *sim*) 1)

  (setf (cl-mpm::sim-gravity *sim*) 0d0)
  (cl-mpm:update-sim *sim*)
  (let ((mesh (cl-mpm:sim-mesh *sim*))
        (mps (cl-mpm::sim-mps *sim*))
        (dt 1d0))
    (let ((dt-test 0d0)
          (iters 100))
      ;(setf dt-test 1d0)
      (setf dt-test
            (time-form
              iters
              (progn
                ;(cl-mpm::update-sim *sim*)
                (cl-mpm::update-stress mesh mps 1d0 nil)
                )))
      (when (= (cl-mpi:mpi-comm-rank) 0) 
        (with-open-file (stream  *data-file* :direction :output :if-exists :append)
          (format stream "~A,~D,~E,~E,~E~%" *solver* *threads* (float *refine* 0e0) 
                  (float (/ 1d0 dt-test) 0e0) 
                  (float (/ (length (cl-mpm:sim-mps *sim*)) dt-test)
                         0e0)))))))

(defparameter *data-file* (merge-pathnames (format nil "data_~A.csv" *name*)))

(when (= (cl-mpi:mpi-comm-rank) 0) 
  (with-open-file (stream *data-file* :direction :output :if-exists nil)
    (format stream "solver,threads,refine,throughput,mp-throughput~%"))
  (format t "Testing thread count: ~D ~%" *threads*)
  (format t "Testing refine: ~E ~%" *refine*))
(test)
(cl-mpi:mpi-waitall)
(test)
(cl-mpi:mpi-waitall)
(test)
(cl-mpi:mpi-waitall)
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
