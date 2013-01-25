(add-to-list 'load-path "~/.emacs.d")
(global-set-key[f5] 'compile)
(require 'xcscope)

(setq org-log-done 'time)
(setq org-log-done 'note)

(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))

(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

(mouse-avoidance-mode 'animate)
;;;让 Emacs 可以直接打开和显示图片
;;;让 Emacs 可以直接打开和显示图片
;
(fset 'yes-or-no-p 'y-or-n-p) ; 将yes/no替换为y/n
;; (global-linum-mode 1)
(cua-mode 1)
(setq frame-title-format "%f") ; 显示当前编辑的文档

(auto-image-file-mode)
;;;让 Emacs 可以直接打开和显示图片

;; (setq default-fill-column 70);默认显示 80列就换行

(if (eq system-type 'gnu/linux)
  (setq initial-frame-alist '((top . 0) (left . 0) (width . 1000) (height . 1000)));;; full size window
  )

(add-to-list 'load-path "~/.emacs.d/ibus-el-0.3.2")
(require 'ibus)
;; Turn on ibus-mode automatically after loading .emacs
(add-hook 'after-init-hook 'ibus-mode-on)
;; Use C-SPC for Set Mark command
(ibus-define-common-key ?\C-\s nil)
;; Use C-/ for Undo command
(ibus-define-common-key ?\C-/ nil)
;; (setq ibus-cursor-color '("red" "blue" "limegreen"))



(if (eq system-type 'gnu/linux)
  (setq org-agenda-files (file-expand-wildcards
                          "/mnt/hgfs/Document/journal/*.org"))
  )

(if (eq system-type 'darwin)
  (setq org-agenda-files (file-expand-wildcards
                          "/Users/carlos/Documents/journal/*.org"))
  )

(defun insert-current_time ()
  (interactive)
  (insert (format-time-string "%Y-%m-%d %H:%M:%S" (current-time))))


(global-set-key (kbd "C-x t") 'org-clock-in)
(global-set-key (kbd "C-x s") 'org-clock-out)

(setq compilation-scroll-output t)
(setq indent-tabs-mode nil)

(dolist (command '(yank yank-pop))
  (eval
   `(defadvice ,command (after indent-region activate)
      (and (not current-prefix-arg)
           (member major-mode
                   '(emacs-lisp-mode
                     lisp-mode
                     clojure-mode
                     scheme-mode
                     haskell-mode
                     ruby-mode
                     rspec-mode
                     python-mode
                     c-mode
                     c++-mode
                     objc-mode
                     latex-mode
                     js-mode
                     plain-tex-mode))
           (let ((mark-even-if-inactive transient-mark-mode))
             (indent-region (region-beginning) (region-end) nil))))))
(defun qiang-comment-dwim-line (&optional arg)
  "Replacement for the comment-dwim command.
If no region is selected and current line is not blank and we are not at the end of the line,
then comment current line.
Replaces default behaviour of comment-dwim, when it inserts comment at the end of the line."
  (interactive "*P")
  (comment-normalize-vars)
  (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
      (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    (comment-dwim arg)))
(global-set-key "\M-;" 'qiang-comment-dwim-line)
(global-set-key (kbd "C-x g") 'grep)
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
(ac-config-default)
(setq global-auto-complete-mode t)
(set-language-environment "utf-8")
(set-default-font "-adobe-Source Code Pro-normal-normal-normal-*-15-*-*-*-m-0-iso10646-1")
(require 'smex)
(global-set-key "\C-x\m" 'smex)
(global-set-key "\C-c\m" 'smex)
(global-set-key "\M-x"  'smex)
;; author: pluskid
;; 调用 stardict 的命令行程序 sdcv 来查辞典
;; 如果选中了 region 就查询 region 的内容，否则查询当前光标所在的单词
;; 查询结果在一个叫做 *sdcv* 的 buffer 里面显示出来，在这个 buffer 里面
;; 按 q 可以把这个 buffer 放到 buffer 列表末尾，按 d 可以查询单词
(global-set-key (kbd "C-c d") 'kid-sdcv-to-buffer)
(defun kid-sdcv-to-buffer ()
  (interactive)
  (let ((word (if mark-active
                  (buffer-substring-no-properties (region-beginning) (region-end))
                (current-word nil t))))
    (setq word (read-string (format "Search the dictionary for (default %s): " word)
                            nil nil word))
    (set-buffer (get-buffer-create "*sdcv*"))
    (buffer-disable-undo)
    (erase-buffer)
    (let ((process (start-process-shell-command "sdcv" "*sdcv*" "sdcv" "-n" word)))
      (set-process-sentinel
       process
       (lambda (process signal)
         (when (memq (process-status process) '(exit signal))
           (unless (string= (buffer-name) "*sdcv*")
             (setq kid-sdcv-window-configuration (current-window-configuration))
             (switch-to-buffer-other-window "*sdcv*")
             (local-set-key (kbd "d") 'kid-sdcv-to-buffer)
             (local-set-key (kbd "q") (lambda ()
                                        (interactive)
                                        (bury-buffer)
                                        (unless (null (cdr (window-list))) ; only one window
                                          (delete-window)))))
           (goto-char (point-min))))))))


(if (eq system-type 'gnu/linux)
(setq org-capture-templates
      '(("t" "Todo" entry (file+headline "/mnt/hgfs/Document/journal/todo.org" "Tasks")
         "* TODO %?\n  %i\n  %a")
        ("j" "Journal" entry (file+datetree "/mnt/hgfs/Document/journal/journal.org")
         "* %?\nEntered on %U\n  %i\n %a")
        ("n" "Note" entry (file+headline "/mnt/hgfs/Document/journal/notes.org" "Notes")
         "* %U %?\n\n  %i" :prepend t :empty-lines 1)
        ))
)

(if (eq system-type 'darwin)
   (setq org-capture-templates
        '(("t" "Todo" entry (file+headline "/Users/carlos/Documents/journal/todo.org" "Tasks")
           "* TODO %?\n  %i\n  %a")
          ("j" "Journal" entry (file+datetree "/Users/carlos/Documents/journal/journal.org")
           "* %?\nEntered on %U\n  %i\n %a")
          ("n" "Note" entry (file+headline "/Users/carlos/Documents/journal/notes.org" "Notes")
           "* %U %?\n\n  %i" :prepend t :empty-lines 1)
          ))
)

(define-key global-map "\C-cc" 'org-capture)
(require 'fuzzy)
(turn-on-fuzzy-isearch)
(setq org-todo-keywords
      '((sequence "TODO(t)" "DOING(i)" "|" "DONE(d)")
        ))

(setq org-tag-alist '(("@work" . ?w) ("@home" . ?h)))

(setq make-backup-files nil) ; stop creating those backup~ files
(setq auto-save-default nil) ; stop creating those #auto-save# files
(global-auto-revert-mode t)


(define-key global-map  "\C-css" 'cscope-find-this-symbol)
(define-key global-map  "\C-csd" 'cscope-find-global-definition)
(define-key global-map  "\C-csg" 'cscope-find-global-definition)
(define-key global-map  "\C-csc" 'cscope-find-functions-calling-this-function)
(define-key global-map  "\C-csC" 'cscope-find-called-functions)
(define-key global-map  "\C-cst" 'cscope-find-this-text-string)
(define-key global-map  "\C-cse" 'cscope-find-egrep-pattern)
(define-key global-map  "\C-csf" 'cscope-find-this-file)
(define-key global-map  "\C-csi" 'cscope-find-files-including-file)
;;          global-map  
(define-key global-map  "\C-csL" 'cscope-create-list-of-files-to-index)
(define-key global-map  "\C-csI" 'cscope-index-files)
(define-key global-map  "\C-csE" 'cscope-edit-list-of-files-to-index)
(define-key global-map  "\C-csW" 'cscope-tell-user-about-directory)
(define-key global-map  "\C-csS" 'cscope-tell-user-about-directory)
(define-key global-map  "\C-csT" 'cscope-tell-user-about-directory)
(define-key global-map  "\C-csD" 'cscope-dired-directory)

(desktop-save-mode 1)
