;;; prelude-editor.el --- Emacs Prelude: enhanced core editing experience.
;;
;; copyright © 2011-2013 Bozhidar Batsov
;;
;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: http://batsov.com/emacs-prelude
;; Version: 1.0.0
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Refinements of the core editing experience in Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;; customize
(defgroup prelude nil
  "Emacs Prelude configuration."
  :prefix "prelude-"
  :group 'convenience)

(defcustom prelude-auto-save t
  "Non-nil values enable Prelude's auto save."
  :type 'boolean
  :group 'prelude)

(defcustom prelude-guru t
  "Non-nil values enable guru-mode"
  :type 'boolean
  :group 'prelude)

(defcustom prelude-whitespace t
  "Non-nil values enable Prelude's whitespace visualization."
  :type 'boolean
  :group 'prelude)

(defcustom prelude-flyspell t
  "Non-nil values enable Prelude's flyspell support."
  :type 'boolean
  :group 'prelude)

;; Death to the tabs!  However, tabs historically indent to the next
;; 8-character offset; specifying anything else will cause *mass*
;; confusion, as it will change the appearance of every existing file.
;; In some cases (python), even worse -- it will change the semantics
;; (meaning) of the program.
;;
;; Emacs modes typically provide a standard means to change the
;; indentation width -- eg. c-basic-offset: use that to adjust your
;; personal indentation width, while maintaining the style (and
;; meaning) of any files you load.
(setq-default indent-tabs-mode nil)   ;; don't use tabs to indent
(setq-default tab-width 8)            ;; but maintain correct appearance

;; delete the selection with a keypress
(delete-selection-mode t)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; revert buffers automatically when underlying files are changed externally
(global-auto-revert-mode t)

;; hippie expand is dabbrev expand on steroids
(setq hippie-expand-try-functions-list '(try-expand-dabbrev
                                         try-expand-dabbrev-all-buffers
                                         try-expand-dabbrev-from-kill
                                         try-complete-file-name-partially
                                         try-complete-file-name
                                         try-expand-all-abbrevs
                                         try-expand-list
                                         try-expand-line
                                         try-complete-lisp-symbol-partially
                                         try-complete-lisp-symbol))

;; smart pairing for all
(electric-pair-mode t)

;; meaningful names for buffers with the same name
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)
(setq uniquify-separator "/")
(setq uniquify-after-kill-buffer-p t)    ; rename after killing uniquified
(setq uniquify-ignore-buffers-re "^\\*") ; don't muck with special buffers

;; saveplace remembers your location in a file when saving files
(setq save-place-file (expand-file-name "saveplace" prelude-savefile-dir))
;; activate it for all buffers
(setq-default save-place t)
(require 'saveplace)

;; savehist keeps track of some history
(setq savehist-additional-variables
      ;; search entries
      '(search ring regexp-search-ring)
      ;; save every minute
      savehist-autosave-interval 60
      ;; keep the home clean
      savehist-file (expand-file-name "savehist" prelude-savefile-dir))
(savehist-mode t)

;; save recent files
(setq recentf-save-file (expand-file-name "recentf" prelude-savefile-dir)
      recentf-max-saved-items 200
      recentf-max-menu-items 15)
(recentf-mode t)

;; time-stamps
;; when there's "Time-stamp: <>" in the first 10 lines of the file
(setq time-stamp-active t
      ;; check first 10 buffer lines for Time-stamp: <>
      time-stamp-line-limit 10
      time-stamp-format "%04y-%02m-%02d %02H:%02M:%02S (%u)") ; date format
(add-hook 'write-file-hooks 'time-stamp) ; update when saving

;; use shift + arrow keys to switch between visible buffers
(require 'windmove)
(windmove-default-keybindings)

;; automatically save buffers associated with files on buffer switch
;; and on windows switch
(defun prelude-auto-save-command ()
  (when (and prelude-auto-save
             buffer-file-name
             (buffer-modified-p (current-buffer)))
    (save-buffer)))

(defadvice switch-to-buffer (before save-buffer-now activate)
  (prelude-auto-save-command))
(defadvice other-window (before other-window-now activate)
  (prelude-auto-save-command))
(defadvice windmove-up (before other-window-now activate)
  (prelude-auto-save-command))
(defadvice windmove-down (before other-window-now activate)
  (prelude-auto-save-command))
(defadvice windmove-left (before other-window-now activate)
  (prelude-auto-save-command))
(defadvice windmove-right (before other-window-now activate)
  (prelude-auto-save-command))

(add-hook 'mouse-leave-buffer-hook 'prelude-auto-save-command)

;; show-paren-mode: subtle highlighting of matching parens (global-mode)
(show-paren-mode +1)
(setq show-paren-style 'parenthesis)

;; highlight the current line
(global-hl-line-mode +1)

(require 'volatile-highlights)
(volatile-highlights-mode t)

;; note - this should be after volatile-highlights is required
;; add the ability to copy and cut the current line, without marking it
(defadvice kill-ring-save (before slick-copy activate compile)
  "When called interactively with no active region, copy a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (message "Copied line")
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

;; tramp, for sudo access
(require 'tramp)
;; keep in mind known issues with zsh - see emacs wiki
(setq tramp-default-method "ssh")

;; ido-mode
(ido-mode t)
(setq ido-enable-prefix nil
      ido-enable-flex-matching t
      ido-create-new-buffer 'always
      ido-use-filename-at-point 'guess
      ido-max-prospects 10
      ido-save-directory-list-file (expand-file-name "ido.hist" prelude-savefile-dir)
      ido-default-file-method 'selected-window)

;; auto-completion in minibuffer
(icomplete-mode +1)

(set-default 'imenu-auto-rescan t)

;; flyspell-mode does spell-checking on the fly as you type
(setq ispell-program-name "aspell" ; use aspell instead of ispell
      ispell-extra-args '("--sug-mode=ultra"))
(autoload 'flyspell-mode "flyspell" "On-the-fly spelling checker." t)

(defun prelude-enable-flyspell ()
  (when (and prelude-flyspell (executable-find ispell-program-name))
    (flyspell-mode +1)))

(defun prelude-enable-whitespace ()
  (when prelude-whitespace
    ;; keep the whitespace decent all the time (in this buffer)
    (add-hook 'before-save-hook 'whitespace-cleanup nil t)
    (whitespace-mode +1)))

(add-hook 'text-mode-hook 'prelude-enable-flyspell)
(add-hook 'text-mode-hook 'prelude-enable-whitespace)

;; enable narrowing commands
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)
(put 'narrow-to-defun 'disabled nil)

;; enabled change region case commands
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(require 'expand-region)

;; bookmarks
(setq bookmark-default-file (expand-file-name "bookmarks" prelude-savefile-dir)
      bookmark-save-flag 1)

;; load yasnippet
(require 'yasnippet)
(add-to-list 'yas-snippet-dirs prelude-snippets-dir)
(add-to-list 'yas-snippet-dirs prelude-personal-snippets-dir)
(yas-global-mode 1)

;; projectile is a project management mode
(require 'projectile)
(setq projectile-cache-file (expand-file-name  "projectile.cache" prelude-savefile-dir))
(projectile-global-mode t)

(require 'helm-misc)
(require 'helm-projectile)

(defun helm-prelude ()
  "Preconfigured `helm'."
  (interactive)
  (condition-case nil
    (if (projectile-project-root)
        ;; add project files and buffers when in project
        (helm-other-buffer '(helm-c-source-projectile-files-list
                             helm-c-source-projectile-buffers-list
                             helm-c-source-buffers-list
                             helm-c-source-recentf
                             helm-c-source-buffer-not-found)
                           "*helm prelude*")
      ;; otherwise fallback to helm-mini
      (helm-mini))
    ;; fall back to helm mini if an error occurs (usually in projectile-project-root)
    (error (helm-mini))))

;; shorter aliases for ack-and-a-half commands
(defalias 'ack 'ack-and-a-half)
(defalias 'ack-same 'ack-and-a-half-same)
(defalias 'ack-find-file 'ack-and-a-half-find-file)
(defalias 'ack-find-file-same 'ack-and-a-half-find-file-same)

;; dired - reuse current buffer by pressing 'a'
(put 'dired-find-alternate-file 'disabled nil)

;; ediff - don't start another frame
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; clean up obsolete buffers automatically
(require 'midnight)

;; automatically indenting yanked text if in programming-modes
(defvar yank-indent-modes
  '(clojure-mode scala-mode python-mode LaTeX-mode TeX-mode)
  "Modes in which to indent regions that are yanked (or yank-popped). Only
modes that don't derive from `prog-mode' should be listed here.")

(defvar yank-advised-indent-threshold 1000
  "Threshold (# chars) over which indentation does not automatically occur.")

(defun yank-advised-indent-function (beg end)
  "Do indentation, as long as the region isn't too large."
  (if (<= (- end beg) yank-advised-indent-threshold)
      (indent-region beg end nil)))

(defadvice yank (after yank-indent activate)
  "If current mode is one of 'yank-indent-modes,
indent yanked text (with prefix arg don't indent)."
  (if (and (not (ad-get-arg 0))
           (or (derived-mode-p 'prog-mode)
               (member major-mode yank-indent-modes)))
      (let ((transient-mark-mode nil))
    (yank-advised-indent-function (region-beginning) (region-end)))))

(defadvice yank-pop (after yank-pop-indent activate)
  "If current mode is one of 'yank-indent-modes,
indent yanked text (with prefix arg don't indent)."
  (if (and (not (ad-get-arg 0))
           (or (derived-mode-p 'prog-mode)
               (member major-mode yank-indent-modes)))
    (let ((transient-mark-mode nil))
    (yank-advised-indent-function (region-beginning) (region-end)))))

;; abbrev config
(add-hook 'text-mode-hook 'abbrev-mode)

;; make a shell script executable automatically on save
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)

;; whitespace-mode config
(setq whitespace-line-column 80) ;; limit line length
(setq whitespace-style '(face tabs empty trailing lines-tail))

;; saner regex syntax
(require 're-builder)
(setq reb-re-syntax 'string)

(require 'eshell)
(setq eshell-directory-name (expand-file-name "eshell" prelude-savefile-dir))

(setq semanticdb-default-save-directory
      (expand-file-name "semanticdb" prelude-savefile-dir))

;; enable Prelude's keybindings
(prelude-global-mode t)

;; enable winner-mode to manage window configurations
(winner-mode +1)

(provide 'prelude-editor)

;;; prelude-editor.el ends here
