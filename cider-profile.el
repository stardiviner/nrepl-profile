;;; cider-profile.el --- CIDER profiling support -*- lexical-binding: t -*-

;; Copyright © 2014 Edwin Watkeys
;;
;; Author: Edwin Watkeys <edw@poseur.com>
;; Version: 0.1.0
;; Package-Requires: ((cider "0.8.0"))
;; Keywords: cider, clojure, profiling
;; URL: http://github.com/thunknyc/nrepl-profile

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package augments CIDER to provide coarse-grained interactive
;; profiling support.

;;; Installation:

;; Available as a package in melpa.milkbox.net.
;;
;; (add-to-list 'package-archives
;;              '("melpa" . "http://melpa.milkbox.net/packages/") t)
;;
;; M-x package-install cider-profile
;;
;; On the Clojure side, add `[thunknyc/nrepl-profile "0.1.0-SNAPSHOT"]`
;; to the vector associated with the `:plugins` key of your `:user`
;; profile inside `${HOME}/.lein/profiles.clj`. Schematically, like
;; this:
;;
;; ```clojure
;; {:user {:plugins [[thunknyc/nrepl-profile "0.1.0-SNAPSHOT"]]}}
;; ```
;;
;; Profiling is a rich and varied field of human endeavour. I encourage
;; you to consider what you're trying to accomplish by profiling. This
;; package for CIDER may not be suited to your current needs. What is
;; nrepl-profile good for? It's intended for interactive, coarse-grained
;; profiling applications where JVM warm-up and garbage collection are
;; not concerns. If you are doing numeric computing or writing other
;; processor-intensive code, I recommend you check out
;; [Criterium](https://github.com/hugoduncan/criterium).
;;
;; On the other hand, if you are primarily concerned about the influence
;; of JVM-exogenous factors on your code—HTTP requests, SQL queries,
;; other network- or (possibly) filesystem-accessing operations—then this
;; package may be just what the doctor ordered.

;;; Usage:

;; Add the following to your `init.el`, `.emacs`, whatever:
;;
;; ```
;; (add-hook 'cider-mode-hook 'cider-profile-mode)
;; (add-hook 'cider-repl-mode-hook 'cider-profile-mode)
;; ```
;;
;; Cider-profile includes the following keybindings out of the box:
;;
;; * `C-c M-=` toggles profiling status.
;; * `C-c M--` displays profiling data to `*err*`.
;; * `C-c M-_` clears collected profiling data.

(require 'cider)

;;;###autoload
(defun cider-profile-toggle (query)
  "Toggle profiling for the given QUERY.
Defaults to the symbol at point.  With prefix arg or no symbol at
point, prompts for a var."
  (interactive "P")
  (cider-ensure-op-supported "toggle-profile")
  (cider-read-symbol-name
   "Toggle profiling for var: "
   (lambda (sym)
     (let ((ns (cider-current-ns)))
       (nrepl-send-request
        (list "op" "toggle-profile"
              "ns" ns
              "sym" sym)
        (nrepl-make-response-handler
         (current-buffer)
         (lambda (_buffer value)
           (cond ((equal value "profiled")
                  (message (format "profiling %s/%s." ns sym)))
                 ((equal value "unprofiled")
                  (message (format "not profiling %s/%s." ns sym)))
                 ((equal value "unbound")
                  (message (format "%s/%s is not bound." ns sym)))))
         '()
         '()
         '()))))
   query))

;;;###autoload
(defun cider-profile-summary (query)
  "Display a summary of currently collected profile data."
  (interactive "P")
  (cider-ensure-op-supported "profile-summary")
  (nrepl-send-request
   (list "op" "profile-summary")
   (cider-interactive-eval-handler (current-buffer)))
  query)

;;;###autoload
(defun cider-profile-clear (query)
  "Clear any collected profile data."
  (interactive "P")
  (cider-ensure-op-supported "clear-profile")
  (nrepl-send-request
   (list "op" "clear-profile")
   (nrepl-make-response-handler
    (current-buffer)
    (lambda (_buffer value)
      (when (equal value "cleared")
        (message "cleared profile data.")))
    '()
    '()
    '()))
  query)

(define-minor-mode cider-profile-mode
  "Toggle cider-profile-mode."
  nil
  nil
  `((,(kbd "C-c M-=") . cider-profile-toggle)
    (,(kbd "C-c M-_") . cider-profile-clear)
    (,(kbd "C-c M--") . cider-profile-summary)))

(provide 'cider-profile)

;;; cider-profile.el ends here
