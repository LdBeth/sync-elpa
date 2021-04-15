
(library (elpa)
  (export sync-elpa)
  (import (chezscheme))
(define (read-archive)
  (call-with-input-file "archive-contents"
    (lambda (o)
      (read o))))

(define (read-remote-pkgs)
  (read (car (process
              (string-append "exec curl -s " remote "archive-contents")))))

(define (fmt-pkg name ver kind)
  (format "~s-~{~s.~}~s" name ver
          (case kind
            [tar 'tar]
            [single 'el])))

(define (process-data data)
  (let ([pkgs (cdr data)]
        [table (make-eq-hashtable)])
      (for-each
       (lambda (x)
         [let ([name (car x)]
               [ver (cadr x)]
               [kind (list-ref x 4)])
           (hashtable-set! table name (list ver kind))
           ;; (display (fmt-pkg name ver kind))
           ;; (newline)
           ])
       pkgs)
      table))

(define (get-difference table data)
  (if (atom? data)
      (error 'get-difference "failed to read remote archive-contents"))
  (let ([pkgs (cdr data)])
    (fold-left
     (lambda (xs x)
       (let* ([name (car x)]
              [ver (cadr x)]
              [kind (list-ref x 4)]
              [old (hashtable-ref table name #f)])
         (if (not (and old (equal? old (list ver kind))))
             (cons (fmt-pkg name ver kind) xs)
             [begin
               (hashtable-delete! table name)
               xs])))
     '() pkgs)))

(define (update-diffs pending)
  (for-each download
            pending))

#|
;; hashtable-cells not available on 9.5

(define (cleanup-files table)
  (vector-for-each (lambda (x)
                     (delete (apply fmt-pkg (car x) (cdr x))))
                   (hashtable-cells table)))
|#

(define (cleanup-files table)
  (vector-for-each (lambda (x)
                     (delete (apply fmt-pkg x (hashtable-ref table x #f))))
                   (hashtable-keys table)))

(define (pipe in out)
  (let ([buf (make-string 1000)])
    (let aux ([input (block-read in buf)])
      (when (number? input)
        (display "*")
        (block-write out buf input)
        (aux (block-read in buf))))))

(define (with-parallel f)
  (let* ([p (process "exec parallel -j 4")]
         [in (car p)])
    (fluid-let ([parallel (cadr p)])
      [dynamic-wind
        (lambda () #f)
        f
        (lambda ()
          ;; send eof
          (write-char (integer->char 4) parallel)
          (format #t "end parallel~%")
          (pipe in log-output)
          (format #t "end pipe~%"))])))

;; variables
(define remote)
(define parallel)
(define log-output
  (standard-output-port 'none (make-transcoder (utf-8-codec))))
(define dry-run #f)

;;(define send system)

(define (send s)
  (if dry-run
      (format #t "run: ~a~%" s)
      [begin (display-string s parallel)
             (newline parallel)]))

(define (download f)
  (send (string-append "axel " remote f)))

(define (delete f)
  (if dry-run
      (format #t "remove file: ~a~%" f)
      (delete-file f)))

(define (sync-elpa dry url)
  [fluid-let ([remote url]
              [dry-run dry])
    (let* ([local-data (read-archive)]
           [remote-data (read-remote-pkgs)]
           [table (process-data local-data)]
           [diff (get-difference table remote-data)])
      (if (null? diff)
          (format #t "nothing to do.~%")
          [with-parallel
           (lambda ()
             (format #t "update diffs.~%")
             (update-diffs diff)
             (format #t "update index.~%")
             (delete "archive-contents.tmp")
             (unless dry-run
               (send (string-append "axel -o archive-contents.tmp " remote
                                    "archive-contents && mv archive-contents.tmp archive-contents")))
             (format #t "clean up files.~%")
             (cleanup-files table)
             )]))])
)
