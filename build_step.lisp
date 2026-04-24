(sb-ext:restrict-compiler-policy 'speed 3 3)
(sb-ext:restrict-compiler-policy 'debug 0 0)
(sb-ext:restrict-compiler-policy 'safety 0 0)
(setf *block-compile-default* t)
(ql:quickload :cl-mpm/settings)
(setf cl-mpm/settings::*optimise-setting* cl-mpm/settings::*optimise-speed*)
(ql:quickload :cl-mpm/examples/collapse)
(ql:quickload :cl-mpm/implicit)
(ql:quickload :serapeum)
(in-package   :cl-mpm/examples/collapse)


(defun main (&optional args)
  (load "test.lisp"))

(sb-ext:gc :full t)
(sb-ext:save-lisp-and-die
   "mpi-worker"
    :executable t
    :toplevel #'main
    :compression nil
    :save-runtime-options t)
(uiop:quit)
