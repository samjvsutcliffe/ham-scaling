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

(when (= (cl-mpi:mpi-comm-rank) 0)
    (format t "Starting test~%") )


(defun setup-domain-decomp (sim)
  (setf cl-mpm/mpi::*prune-nodes* nil)
  (when (= (cl-mpi:mpi-comm-rank) 0)
    (format t "Starting domain decompose~%"))
  (setf (cl-mpm/mpi::mpm-sim-mpi-domain-count sim)
	    (list (floor (cl-mpi:mpi-comm-size)) 1 1))
  (cl-mpm/mpi::domain-decompose sim)
  (cl-mpm/mpi::load-balance-algo sim)
  (when (= (cl-mpi:mpi-comm-rank) 0)
    (format t "Ending domain decompose~%")))

(defun get-mps-length (sim)
  (round (cl-mpm/mpi::mpi-sum (float (length (cl-mpm:sim-mps sim)) 0d0))))

(defmacro time-form-mpi (it form)
  `(progn
     (declaim (optimize speed))
     (let* ((iterations ,it)
            (start (get-internal-real-time)))
       (time
        (progn
          (dotimes (i ,it)
            ,form)
          (cl-mpi:mpi-waitall)))
       (let* ((end (get-internal-real-time))
              (units internal-time-units-per-second)
              (dt (/ (- end start) (* iterations units))))

         (let ((mps-length (get-mps-length *sim*)))
           (when (= (cl-mpi:mpi-comm-rank) 0)
             (format t "Total time: ~f ~%" (/ (- end start) units)) (format t "Time per iteration: ~f~%" (/ (- end start) (* iterations units)))
             (format t "Throughput: ~f~%" (/ 1 dt))
             (format t "Time per MP: ~E~%" (/ dt mps-length))))
         dt))))

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
            (time-form-mpi
              iters
              (progn
                (cl-mpm::update-sim *sim*)
                ;(cl-mpm::update-stress mesh mps 1d0 nil)
                )))
      (let ((mp-count (get-mps-length *sim*)))
        (when (= (cl-mpi:mpi-comm-rank) 0) 
          (with-open-file (stream  *data-file* :direction :output :if-exists :append)
            (format stream "~A,~D,~E,~E,~E~%" *solver* *threads* (float *refine* 0e0) 
                    (float (/ 1d0 dt-test) 0e0) 
                    (float (/ mp-count dt-test)
                           0e0))))))))

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
