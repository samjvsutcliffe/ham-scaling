(sb-ext:restrict-compiler-policy 'speed 3 3)
(sb-ext:restrict-compiler-policy 'debug 0 0)
(sb-ext:restrict-compiler-policy 'safety 0 0)
(setf *block-compile-default* t)
(declaim (sb-ext:muffle-conditions sb-ext:compiler-note))

;(sb-ext:restrict-compiler-policy 'speed 0 0)
;(sb-ext:restrict-compiler-policy 'debug 3 3)
;(sb-ext:restrict-compiler-policy 'safety 3 3)

;(ql:quickload :magicl)

;(asdf:compile-system :magicl :force t)
(ql:quickload :cl-mpm/settings)
(ql:quickload :parse-float)
(setf cl-mpm/settings::*optimise-setting* cl-mpm/settings::*optimise-speed*)
;(setf cl-mpm/settings::*optimise-setting* cl-mpm/settings::*optimise-debug*)
(ql:quickload :cl-mpm/examples/collapse)
(ql:quickload :cl-mpm/mpi)
(ql:quickload :cl-mpm/dynamic-relaxation-mpi)
(ql:quickload :cl-mpm/implicit)
(ql:quickload :serapeum)
(ql:quickload :cl-mpm-worker)
(in-package :cl-mpm-worker)


(defun main (&optional args)
  (load "test.lisp"))

(sb-ext:gc :full t)
(sb-ext:save-lisp-and-die
   "worker"
    :executable t
    :toplevel #'main
    :compression t
    ;:accept-runtime-options t
    :save-runtime-options nil)
(uiop:quit)
