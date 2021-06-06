#!r6rs
(import (chezscheme))

(define rsync-list
  '[("GNU ELPA" "rsync://elpa.gnu.org/elpa/" "/var/elpa-packages/gnu")
    ("MELPA"
     "rsync://melpa.org/packages/" "/var/elpa-packages/melpa")
    ("MELPA Stable"
     "rsync://melpa.org/packages-stable/" "/var/elpa-packages/melpa-stable")])

(define (rsync name source dist)
  (printf ">>> Syncing ~a <~a>...~%" name (date-and-time))
  (let ([status
         (system
          (format #f "exec rsync -avz --delete --progress --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r ~a ~a"
                  source dist))])
    (printf ">>> Done <~a>~%" (date-and-time))
    status))

(define retry '())

(for-each
 (lambda (x)
   (if (not (= (apply rsync x) 0))
       (set! retry (cons x retry))))
 rsync-list)

(if (not (null? retry))
    (begin
      (printf "detected failure, retry in 10 secs...~%")
      (sleep (make-time 'time-duration 0 10))
      (exit
       (apply max (map
                   (lambda (x)
                     (apply rsync x))
                   retry)))))
