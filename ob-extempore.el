;;; ob-extempore.el --- org-babel functions for extempore evaluation

;; Copyright (C) 2016 Feng Zhou

;; Author: ZHOU Feng <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/ob-extempore
;; Keywords: org babel extempore
;; Version: 0.0.1
;; Created: 1th Apr 2016
;; Package-Requires: ((org "8"))

;;; Commentary:
;;
;; org-babel functions for extempore evaluation
;;

;;; Code:
(require 'ob)

(make-variable-buffer-local 'ob-extempore-connection)
(defvar ob-extempore-connection)
(setq ob-extempore-connection nil)

(make-variable-buffer-local 'ob-extempore-output)
(defvar ob-extempore-output)
(setq ob-extempore-output nil)

(defvar ob-extempore-eoe)
(setq ob-extempore-eoe nil)

(defun org-babel-execute:extempore (body params)
  (ob-extempore-ensure-connection
   (or (assoc-default :host params) "localhost")
   (or (assoc-default :port params) 7099))
  (ob-extempore-send body))

(defun ob-extempore-filter (proc output)
  (let ((str (replace-regexp-in-string "[%\n]" "" (substring output 0 -1))))
    (if (and (> (length str) 16)
             (string= "(xtmdoc-docstring" (substring str 0 17)))
        (if (not (string= "(xtmdoc-docstring-nodocstring)" str))
            (extempore-process-docstring-form (cdr-safe (ignore-errors (read str)))))
      (setq ob-extempore-output (concat ob-extempore-output str)))))

(defun ob-extempore-wait ()
  (while (not (string-match-p ob-extempore-eoe ob-extempore-output))
    (sit-for 0.2)))

(defun ob-extempore-ensure-connection (host port)
  (unless (process-live-p ob-extempore-connection)
          (let ((proc (with-demoted-errors (open-network-stream "extempore" nil host port))))
            (if proc
                (progn
                  (set-process-coding-system proc 'iso-latin-1-unix 'iso-latin-1-unix)
                  (set-process-filter proc 'ob-extempore-filter)
                  (setq ob-extempore-connection proc)
                  (ob-extempore-send ""))
              (message "Could not connect to Extempore at %s:%d" host port)))))

(defun ob-extempore-send (body)
  (let ((transient-mark-mode nil))
    (setq ob-extempore-output nil)
    (process-send-string ob-extempore-connection (concat body "\r\n"))
    (sit-for 1)
    ob-extempore-output))

(provide 'ob-extempore)
;;; ob-extempore.el ends here
