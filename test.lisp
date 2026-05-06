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
(defparameter *threads* (let ((var (uiop:getenv "OMP_NUM_THREADS"))) (parse-integer (if var var "1"))))
(defparameter *solver* (let ((var (uiop:getenv "SOLVER"))) (if var var "DR")))
(defparameter *solver-hash* (serapeum:dict "DR" 'cl-mpm/dynamic-relaxation::mpm-sim-quasi-static "IMPLICIT" 'cl-mpm/implicit::mpm-sim-implicit))

(format t "Running test with settings name ~A refine ~A threads ~A solver ~A~%" *name* *refine* *threads* *solver*)
(setf lparallel:*kernel* (lparallel:make-kernel *threads* :name "custom-kernel"))

(defun setup (&key (refine 1) (mps 2)
                (sim-type 'cl-mpm:mpm-sim-usf)
                (multigrid-refine 0))
  (defparameter *sim* nil)
  (let* ((mps-per-dim mps)
         (h-0 8)
         (hr (* 8 refine))
         (mr (list hr h-0))
         (refine-0 2))
    (setf *sim* (setup-test-column mr mr sim-type refine-0 mps-per-dim multigrid-refine))) 
  (format t "MPs: ~D~%" (length (cl-mpm:sim-mps *sim*)))
  (format t "MPs per thread: ~F~%" (/ (length (cl-mpm:sim-mps *sim*)) *threads*))
  (defparameter *run-sim* t)
  (defparameter *t* 0)
  (defparameter *sim-step* 0))


(declaim (notinline test))
(defun test ()
  (setup
    :refine (round *refine*)
    :mps 2)
  (cl-mpm::domain-sort-mps *sim*)
  (format t "Changing class ~A~%" (gethash *solver* *solver-hash*))
  (change-class *sim* (gethash *solver* *solver-hash*))
  (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) nil 
      (cl-mpm::sim-ghost-factor *sim*) nil
      (cl-mpm::sim-enable-fbar *sim*) nil)
  ;(setf (cl-mpm/dynamic-relaxation::sim-mass-update-count *sim*) 1)
  (setf (cl-mpm::sim-gravity *sim*) 0d0)
  (format t "Starting test~%")
  (cl-mpm:update-sim *sim*)
  (format t "Prestep done~%")
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
                (cl-mpm::update-sim *sim*)
                ;(cl-mpm::update-stress mesh mps 1d0 nil)
                )))
      (with-open-file (stream  *data-file* :direction :output :if-exists :append)
        (format stream "~A,~D,~E,~E,~E~%" *solver* *threads* (float *refine* 0e0) 
                (float (/ 1d0 dt-test) 0e0) 
                (float (/ (length (cl-mpm:sim-mps *sim*)) dt-test)
                       0e0)))))
  
  )
(defparameter *data-file* (merge-pathnames (format nil "data_~A.csv" *name*)))
(with-open-file (stream *data-file* :direction :output :if-exists nil)
    (format stream "solver,threads,refine,throughput,mp-throughput~%"))
(format t "Testing thread count: ~D ~%" *threads*)
(format t "Testing refine: ~E ~%" *refine*)
(dotimes (i 5)
  (test))
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
