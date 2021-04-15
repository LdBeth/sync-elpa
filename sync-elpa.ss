#!r6rs
(import (chezscheme)
        (elpa))

(define elpa-alist
  '(["gnu/" . "http://elpa.gnu.org/packages/"]
    ["melpa/" .  "https://melpa.org/packages/"]))

(define elpa-prefix "/root/elpa-mirror-2021-main/")

(define (help)
  (display-string "usage: sync-elpa logfile")
  (newline))

(let ([args (cdr (command-line))])
  (if (null? args)
      (help)
      (let ([log (car args)])
        (call-with-output-file log
          (lambda (o)
            (for-each
             (lambda (x)
               (cd (string-append elpa-prefix (car x)))
               (sync-elpa #f o (cdr x)))
             elpa-alist))))))
