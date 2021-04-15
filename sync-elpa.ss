#!r6rs
(import (chezscheme)
        (elpa))

(define elpa-alist
  '(["gnu/" . "http://elpa.gnu.org/packages/"]
    ["melpa/" . "https://melpa.org/packages/"]
    ["melpa-stable/". "https://stable.melpa.org/packages/"]))

(define elpa-prefix "/root/elpa-mirror-2021-main/")

(for-each
 (lambda (x)
   (let ([path (string-append elpa-prefix (car x))])
     (format #t "start sync ~a~%" path)
     (cd path)
     (sync-elpa #f (cdr x))))
 elpa-alist)
