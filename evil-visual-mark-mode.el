;;; evil-visual-mark-mode --- Display evil marks on buffer
;;; Commentary:

;; Copyright (C) 2015 Roman Gonzalez.

;; Author: Roman Gonzalez <romanandreg@gmail.com>
;; Maintainer: Roman Gonzalez <romanandreg@gmail.com>
;; Version: 0.0.1
;; Package-Requires: ((evil "1.0.9") (dash "2.10"))
;; Keywords: evil

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  This program is
;; distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.  You should have received a copy of the
;; GNU General Public License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.


(require 'evil)
(require 'dash)

;;; Code:
(defvar evil-visual-mark-overlay-alist '()
  "List of evil visual mark overlays.")

(defface evil-visual-marker-face
  '((t (:foreground "white"
                    :background "color-89"
                    :underline t)))
  "Face for evil visual marks"
  :group 'evil-visual-mark)

(defun evil-visual-mark-make-overlay (marker)
  "Create an overlay for the given MARKER.

This marker will normally come from the advised evil-set-marker
function."
  (let* ((marker-pos (marker-position marker)))
    (make-overlay marker-pos (+ 2 marker-pos))))

(defun evil-visual-mark-overlay-put (char overlay)
  "Puts marker CHAR in created OVERLAY."
  (overlay-put overlay
               'before-string
               (propertize (format "`%c" char)
                           'face
                           'evil-visual-marker-face))
  overlay)


(defun evil-visual-mark-populate-overlay-alist ()
  "Populate the `evil-visual-mark-overlay-alist'.

This function is called when enabling the evil-visual-marker-mode."
  (evil-visual-mark-cleanup)
  (setq evil-visual-mark-overlay-alist
        (->> evil-markers-alist
             (-filter (lambda (it) (markerp (cdr it))))
             (-map
              (lambda (it)
                (let* ((letter     (car it))
                       (marker     (cdr it))
                       (new-item   (list nil nil))
                       (new-overlay (evil-visual-mark-make-overlay marker)))
                  
                  (setf (car new-item) letter)
                  (setf (cdr new-item) new-overlay)

                  
                  new-item))))))


(defun evil-visual-mark-hide ()
  "Hide all evil markers.

This function is called on `evil-normal-state-exit-hook.'"
  (--each evil-visual-mark-overlay-alist
    (overlay-put (cdr it)
                 'before-string
                 "")))

(defun evil-visual-mark-show ()
  "Show all evil markers.

This function is called on `evil-normal-state-entry-hook'."
  (--each evil-visual-mark-overlay-alist
    (evil-visual-mark-overlay-put (car it) (cdr it))))

(defun evil-visual-mark-render ()
  "Render for the first time the evil mark list.

This function is called on the initialization of
`evil-visual-mark-mode'"
  (evil-visual-mark-populate-overlay-alist)
  (--each evil-visual-mark-overlay-alist
    (evil-visual-mark-overlay-put (car it)
                                  (cdr it))))

(defun evil-visual-mark-cleanup ()
  "Remove all overlays that were created by this mode.

This function is called when disabling `evil-visual-mark-mode'"
  (-each evil-visual-mark-overlay-alist
    (lambda (it) (delete-overlay (cdr it))))
  (setq evil-visual-mark-overlay-alist '()))

(defun evil-visual-mark-update-mark (char marker)
  "Update overlay value for CHAR.

This function gets called from advising `evil-set-mark', the MARKER is
the result of calling that function."
  (when (and marker
             (markerp marker))

    (let* ((new-overlay (evil-visual-mark-make-overlay marker))
           (old-item    (assoc char evil-visual-mark-overlay-alist))
           (old-overlay (and old-item (cdr old-item))))

      ;; update overlay state for given char
      (if old-item
          (setf (cdr old-item) new-overlay)
        (let ((new-item (list nil nil)))
          (setf (car new-item) char)
          (setf (cdr new-item) new-overlay)
          (add-to-list 'evil-visual-mark-overlay-alist
                       new-item)))

      ;; delete old overlay from view
      (when old-overlay
        (delete-overlay old-overlay))

      ;; add new overlay to view
      (evil-visual-mark-overlay-put char new-overlay))))

(defadvice evil-set-marker (around compile)
  "Listens when an evil marker is being created/updated.

This updates the overlays that show the evil marks on buffer."
  (let ((char    (ad-get-arg 0))
        (marker  ad-do-it))
    (evil-visual-mark-update-mark char marker)))

(define-minor-mode evil-visual-mark-mode
  "Makes evil marks visible and easy to remember."
  :global t
  (if evil-visual-mark-mode
      (progn
        (ad-activate 'evil-set-marker)
        (add-hook 'evil-normal-state-exit-hook 'evil-visual-mark-hide)
        (add-hook 'evil-normal-state-entry-hook 'evil-visual-mark-show)
        (evil-visual-mark-render))
    (progn
      (ad-deactivate 'evil-set-marker)
      (remove-hook 'evil-normal-state-exit-hook 'evil-visual-mark-hide)
      (remove-hook 'evil-normal-state-entry-hook 'evil-visual-mark-show)
      (evil-visual-mark-cleanup))))


(provide 'evil-visual-mark-mode)

;;; evil-visual-mark-mode ends here
