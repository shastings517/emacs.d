;;; init.el --- Andre Silva's Emacs configuration

;;; Code:

;;; initialization

;; save start time so we can later measure the total loading time
(defconst emacs-start-time (current-time))

;; reduce the frequency of garbage collection by making it happen on
;; every 20MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold (* 20 1000 1000))

;; setup `package' but do not auto-load installed packages
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

;; bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; `use-package' is not needed at runtime
(eval-when-compile
  (require 'use-package))

;; required for the `use-package' :bind keyword
(require 'bind-key)

;; required for the `use-package' :diminish keyword
;; reduce modeline clutter
(require 'diminish)

;;; ui
;;;; font

;; set default font
(set-default-font
 (apply 'font-spec :name "Source Code Pro" '(:size 13 :weight normal :width normal)) nil t)

;; set fallback font
(when (fboundp 'set-fontset-font)
  ;; window numbers
  (set-fontset-font "fontset-default"
                    '(#x2776 . #x2793) "Menlo")
  ;; mode-line circled letters
  (set-fontset-font "fontset-default"
                    '(#x24b6 . #x24fe) "Menlo")
  ;; mode-line additional characters
  (set-fontset-font "fontset-default"
                    '(#x2295 . #x22a1) "Menlo")
  ;; new version lighter
  (set-fontset-font "fontset-default"
                    '(#x2190 . #x2200) "Menlo"))

;;;; settings

;; disable scrollbar
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

;; disable toolbar
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))

;; disable menubar
(menu-bar-mode -1)

;; disable cursor blinking
(blink-cursor-mode -1)

;; disable startup screen
(setq inhibit-startup-screen t)

;; clean up obsolete buffers
(use-package midnight)

;;;; theme

;; use the awesome `zenburn' as default theme
(use-package zenburn-theme
  :ensure t
  :defer t
  :init
  (load-theme 'zenburn :no-confirm))

;;;; osx

;; setup modifier keys on OSX
(when (eq system-type 'darwin)
  (progn
    (use-package exec-path-from-shell
      :ensure t
      :config
      (exec-path-from-shell-initialize))
    (setq mac-command-modifier 'super)
    (setq mac-option-modifier 'meta)
    (setq ns-function-modifier 'hyper)
    ;; enable emoji, and stop the UI from freezing when trying to display them
    (set-fontset-font t 'unicode "Apple Color Emoji" nil 'prepend)))

;;;; helm

;; project navigation
(use-package projectile
  :ensure t
  :config
  (projectile-global-mode))

;; interactive completion
(use-package helm
  :ensure t
  :demand t
  :diminish helm-mode
  :init
  (setq helm-split-window-in-side-p t
        helm-move-to-line-cycle-in-source t
        helm-ff-search-library-in-sexp t
        helm-ff-file-name-history-use-recentf t)
  ;; enable fuzzy matching
  (setq helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match t
        helm-locate-fuzzy-match t
        helm-M-x-fuzzy-match t
        helm-semantic-fuzzy-match t
        helm-imenu-fuzzy-match t
        helm-apropos-fuzzy-match t
        helm-lisp-fuzzy-completion t
        helm-mode-fuzzy-match t
        helm-completion-in-region-fuzzy-match t)
  :config
  (require 'helm-config)
  (helm-mode)
  (helm-autoresize-mode)
  (use-package helm-projectile
    :ensure t
    :init
    (setq projectile-completion-system 'helm)
    (setq helm-projectile-fuzzy-match t)
    :config
    (helm-projectile-on))

  :bind (("M-x"     . helm-M-x)
         ("C-x C-m" . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("C-x C-b" . helm-buffers-list)
         ("C-x b"   . helm-mini)
         ("M-y"     . helm-show-kill-ring)
         ("s-a"     . helm-projectile-ag)
         ("s-f"     . helm-projectile-find-file)))

;;;; god mode

;; modal editing
(use-package god-mode
  :ensure t
  :diminish god-local-mode
  :init
  (defun my-update-cursor ()
    (set-cursor-color
     (if (bound-and-true-p god-local-mode)
         "chartreuse3"
       "DarkGoldenrod2")))
  (add-hook 'god-mode-enabled-hook 'my-update-cursor)
  (add-hook 'god-mode-disabled-hook 'my-update-cursor)

  (setq god-exempt-major-modes nil)
  (setq god-exempt-predicates nil))

;; ergonomic shortcuts
(use-package key-chord
  :ensure t
  :config
  (key-chord-mode 1)
  (key-chord-define-global "jk" 'god-mode-all))

;;;; mode line

;; window numbering and switching
(use-package window-numbering
  :ensure t
  :config
  (window-numbering-mode))

;; fancy mode line with `spaceline'
(use-package spaceline
  :ensure t
  :init
  (defun my-spaceline-highlight-face-god-state ()
    (if (bound-and-true-p god-local-mode)
        'spaceline-evil-insert
      'spaceline-evil-normal))
  (setq spaceline-highlight-face-func 'my-spaceline-highlight-face-god-state)

  (setq spaceline-window-numbers-unicode t)
  (setq powerline-default-separator 'bar)
  :config
  (require 'spaceline-config)
  (spaceline-emacs-theme)
  (spaceline-helm-mode))

;;;; extras

;; show line diff indicator on fringe
(use-package diff-hl
  :ensure t
  :init
  (add-hook 'dired-mode-hook 'diff-hl-dired-mode)
  :config
  (global-diff-hl-mode))

;; highlight useful keywords
(use-package hl-todo
  :ensure t
  :init (add-hook 'prog-mode-hook 'hl-todo-mode))

;; enhanced `dired'
(use-package dired+
  :defer t
  :ensure t)

;; smooth scrolling
(use-package smooth-scrolling
  :ensure t
  :init
  (setq smooth-scroll-margin 5))

;; enhanced `isearch'
(use-package anzu
  :ensure t
  :diminish anzu-mode
  :init
  (setq anzu-cons-mode-line-p nil)
  :config
  (global-anzu-mode))

;; enhanced `list-packages'
(use-package paradox
  :ensure t
  :init
  (setq paradox-github-token t)
  :commands paradox-list-packages)

;; start server if one isn't already running
(use-package server
  :config
  (unless (server-running-p)
    (server-start)))

;; use rvm ruby version
(defun my-init-rvm ()
  (use-package rvm
    :ensure t
    :config
    (rvm-use-default))
  (remove-hook 'ruby-mode-hook 'my-init-rvm)
  (remove-hook 'markdown-mode-hook 'my-init-rvm))
(add-hook 'ruby-mode-hook 'my-init-rvm)
(add-hook 'markdown-mode-hook 'my-init-rvm)

;;; editor
;;;; settings

;; delete selection with a keypress
(delete-selection-mode t)

;; setup `hippie-expand' expand functions
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

;; use `hippie-expand' instead of `dabbrev'
(bind-keys ("M-/" . hippie-expand)
           ("C-ç" . hippie-expand))

;; revert buffers automatically (also enabled for non-file buffers)
(setq global-auto-revert-non-file-buffers t)
(global-auto-revert-mode t)

;; fill-column line length
(setq-default fill-column 100)

;; kill region or current line
(use-package rect
  :config
  (defadvice kill-region (before smart-cut activate compile)
    "When called interactively with no active region, kill a single line instead."
    (interactive
     (if mark-active (list (region-beginning) (region-end) rectangle-mark-mode)
       (list (line-beginning-position)
             (line-beginning-position 2))))))

;;;; white space

;; no tabs please (but make it look like it)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 8)

;; newline at end of file
(setq require-final-newline t)

;; keep white space tidy
(use-package whitespace
  :diminish whitespace-mode
  :init
  (defun my-enable-whitespace-mode ()
    (add-hook 'before-save-hook 'whitespace-cleanup nil t)
    (whitespace-mode +1))
  (add-hook 'text-mode-hook 'my-enable-whitespace-mode)
  (add-hook 'prog-mode-hook 'my-enable-whitespace-mode)
  (setq whitespace-line-column 100)
  (setq whitespace-style '(face tabs empty trailing lines-tail)))

;;;; spell checking

(use-package flyspell
  :diminish flyspell-mode
  :config
  (add-hook 'text-mode-hook 'flyspell-mode)
  (add-hook 'prog-mode-hook 'flyspell-prog-mode))

;;;; packages

;; multiple cursors are easier than macros
(use-package multiple-cursors
  :ensure t)

;; in-buffer auto completion framework
(use-package company
  :ensure t
  :diminish company-mode
  :init
  (setq company-idle-delay 0.5)
  (setq company-tooltip-limit 10)
  (setq company-minimum-prefix-length 2)
  (setq company-selection-wrap-around t)
  :config
  (global-company-mode))

;;; major modes
;;;; git

;; the best git client ever
(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status))

;;;; programming

;; syntax checking
(use-package flycheck
  :ensure t
  :diminish flycheck-mode
  :init
  (setq flycheck-indication-mode nil)
  :config
  (add-hook 'prog-mode-hook 'flycheck-mode))

;;;; scala

;; `scala' programming mode
(use-package scala-mode2
  :ensure t
  :config
  (use-package ensime
    :ensure t
    :init
    (setq ensime-sem-high-enabled-p nil)
    :config
    (add-hook 'scala-mode-hook 'ensime-scala-mode-hook))

  :mode ("\\.\\(scala\\|sbt\\)\\'" . scala-mode))

;;;; rust

;; `rust' programming mode
(use-package rust-mode
  :ensure t
  :init
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-copy-env "RUST_SRC_PATH"))
  :config
  (use-package racer
    :ensure t
    :init
    (add-hook 'rust-mode-hook 'racer-mode)
    (add-hook 'racer-mode-hook 'eldoc-mode))
  (use-package company-racer
    :ensure t
    :config
    (add-to-list 'company-backends 'company-racer))
  :mode ("\\.rust\\'" . rust-mode))

;; needed for `cargo' files
(use-package toml-mode
  :ensure t
  :mode ("\\.toml\\'" . toml-mode))

;;;; emacs lisp

;; fold my `init.el' like an org file
(use-package outshine
  :ensure t
  :diminish outline-minor-mode
  :init
  (add-hook 'emacs-lisp-mode-hook 'outline-minor-mode))

;; interactive lisp macro expansion
(use-package macrostep
  :ensure t
  :commands macrostep-expand
  :init
  (bind-key "C-c e" 'macrostep-expand emacs-lisp-mode-map))

;;;; shell

(use-package sh-script
  :defer t
  :init
  ;; Use sh-mode when opening `.zsh' files, and when opening Prezto runcoms
  (dolist (pattern '("\\.zsh\\'"
                     "zlogin\\'"
                     "zlogout\\'"
                     "zpreztorc\\'"
                     "zprofile\\'"
                     "zshenv\\'"
                     "zshrc\\'"))
    (add-to-list 'auto-mode-alist (cons pattern 'sh-mode)))
  (defun my-init-sh-mode ()
    (when (and buffer-file-name
               (string-match-p "\\.zsh\\'" buffer-file-name))
      (sh-set-shell "zsh")))
  (add-hook 'sh-mode-hook 'my-init-sh-mode))

;;;; markdown

;; setup `markdown-mode' to render with redcarpet
(use-package markdown-mode
  :ensure t
  :init
  (setq markdown-command "redcarpet --parse tables")
  (setq markdown-command-needs-filename t)
  :mode ("\\.md\\'" . markdown-mode))

;;;; yaml

;; `yaml' mode
(use-package yaml-mode
  :ensure t
  :mode (("\\.\\(yml\\|yaml\\)\\'" . yaml-mode)
         ("Procfile\\'"            . yaml-mode)))

;;;; web

;; web programming mode
(use-package web-mode
  :ensure t
  :config
  (use-package company-web
    :ensure t
    :config
    (push '(company-web-html company-css) company-backends-web-mode))
  :mode (("\\.phtml\\'"      . web-mode)
         ("\\.tpl\\.php\\'"  . web-mode)
         ("\\.twig\\'"       . web-mode)
         ("\\.html\\'"       . web-mode)
         ("\\.htm\\'"        . web-mode)
         ("\\.[gj]sp\\'"     . web-mode)
         ("\\.as[cp]x?\\'"   . web-mode)
         ("\\.eex\\'"        . web-mode)
         ("\\.erb\\'"        . web-mode)
         ("\\.mustache\\'"   . web-mode)
         ("\\.handlebars\\'" . web-mode)
         ("\\.hbs\\'"        . web-mode)
         ("\\.eco\\'"        . web-mode)
         ("\\.jsx\\'"        . web-mode)
         ("\\.ejs\\'"        . web-mode)
         ("\\.djhtml\\'"     . web-mode)))

;;;; rest client

;; interact with HTTP APIs
(use-package restclient
  :ensure t
  :mode ("\\.http\\'" . restclient-mode))

;;;; org

;; `org-mode'
(use-package org
  :init
  ;; log time when task is finished
  (setq org-log-done 'time)
  ;; org directory and agenda files
  (setq org-directory "~/org")
  (setq org-agenda-files (quote ("~/org/todo.org"
                                 "~/org/projects"
                                 "~/org/journal")))
  (setq org-default-notes-file "~/org/refile.org")
  ;; include numeric filenames in regexp (for journal files)
  (setq org-agenda-file-regexp "'\\`[^.].*\\.org'\\|[0-9]+")
  ;; org keywords and faces
  (setq org-todo-keywords
        (quote ((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d)")
                (sequence "WAITING(w@/!)" "HOLD(h@/!)" "|" "CANCELED(c@/!)"))))
  (setq org-todo-keyword-faces
        (quote
         ;; normal org-mode workflow
         (("TODO" :foreground "red" :weight bold)
          ("STARTED" :foreground "dodger blue" :weight bold)
          ("DONE" :foreground "forest green" :weight bold)
          ("WAITING" :foreground "orange" :weight bold)
          ("HOLD" :foreground "magenta" :weight bold)
          ("CANCELED" :foreground "forest green" :weight bold)
          ;; music queue workflow
          ("ADDED" :foreground "red" :weight bold)
          ("DOWNLOADED" :foreground "dodger blue" :weight bold)
          ("IMPORTED" :foreground "orange" :weight bold)
          ("LISTENED" :foreground "forest green" :weight bold))))
  ;; state triggers
  (setq org-todo-state-tags-triggers
        (quote (("CANCELED" ("CANCELED" . t))
                ("WAITING"  ("WAITING"  . t))
                ("HOLD"     ("WAITING"  . t) ("HOLD" . t))
                (done       ("WAITING")      ("HOLD"))
                ("TODO"     ("WAITING")      ("CANCELED") ("HOLD"))
                ("STARTED"  ("WAITING")      ("CANCELED") ("HOLD"))
                ("DONE"     ("WAITING")      ("CANCELED") ("HOLD")))))
  ;; use fast todo selection
  (setq org-use-fast-todo-selection t)
  (setq org-treat-S-cursor-todo-selection-as-state-change nil)
  ;; show lots of clocking history so it's easy to pick items off the C-F11 list
  (setq org-clock-history-length 36)
  ;; resume clocking task on clock-in if the clock is open
  (setq org-clock-in-resume t)
  ;; change tasks to STARTED when clocking in
  (setq org-clock-in-switch-to-state "STARTED")
  ;; separate drawers for clocking and logs
  (setq org-drawers (quote ("PROPERTIES" "LOGBOOK")))
  ;; save clock data and state changes and notes in the LOGBOOK drawer
  (setq org-clock-into-drawer t)
  ;; sometimes I change tasks I'm clocking quickly - this removes clocked tasks with 0:00 duration
  (setq org-clock-out-remove-zero-time-clocks t)
  ;; clock out when moving task to a done state
  (setq org-clock-out-when-done t)
  ;; save the running clock and all clock history when exiting Emacs, load it on startup
  (setq org-clock-persist t)
  ;; do not prompt to resume an active clock
  (setq org-clock-persist-query-resume nil)
  ;; enable auto clock resolution for finding open clocks
  (setq org-clock-auto-clock-resolution (quote when-no-clock-is-running))
  ;; include current clocking task in clock reports
  (setq org-clock-report-include-clocking-task t)
  ;; set default column format
  (setq org-columns-default-format
        "%40ITEM %TODO %5Effort(Effort){:} %6CLOCKSUM")
  ;; enable org-indent-mode
  (setq org-startup-indented t)
  ;; handle empty lines
  (setq org-cycle-separator-lines 0)
  (setq org-blank-before-new-entry (quote ((heading)
                                           (plain-list-item . auto))))
  ;; templates
  (setq org-capture-templates
        (quote (("t" "Todo" entry (file+headline "~/org/refile.org" "Tasks")
                 "* TODO %?")
                ("i" "Todo+Iteration" entry (file+headline "~/org/refile.org" "Tasks")
                 "* TODO %? %^{Iteration}p"))))
  ;; refiling
  ;; targets include this file and any file contributing to the agenda - up to 9 levels deep
  (setq org-refile-targets (quote ((nil :maxlevel . 9)
                                   (org-agenda-files :maxlevel . 9))))
  ;; use full outline paths for refile targets - we file directly with ido
  (setq org-refile-use-outline-path t)
  ;; targets complete directly with ido
  (setq org-outline-path-complete-in-steps nil)
  ;; allow refile to create parent tasks with confirmation
  (setq org-refile-allow-creating-parent-nodes (quote confirm))
  ;; use ido for both buffer and file completion and ido-everywhere to t
  (setq org-completion-use-ido t)
  ;; babel
  ;; enable syntax highlighting
  (setq org-src-fontify-natively t)
  ;; do not prompt to confirm evaluation
  (setq org-confirm-babel-evaluate nil)
  ;; org-pomodoro
  ;; reduce volume of the bell sounds
  (setq org-pomodoro-start-sound-args "-v 0.3")
  (setq org-pomodoro-finished-sound-args "-v 0.3")
  (setq org-pomodoro-killed-sound-args "-v 0.3")
  (setq org-pomodoro-short-break-sound-args "-v 0.3")
  (setq org-pomodoro-long-break-sound-args "-v 0.3")
  (setq org-pomodoro-ticking-sound-args "-v 0.3")
  :config
  ;; resume clocking task when emacs is restarted
  (org-clock-persistence-insinuate)
  ;; enable languages in babel
  (org-babel-do-load-languages
   (quote org-babel-load-languages)
   (quote ((scheme . t)
           (sh     . t)
           (org    . t)
           (latex  . t))))
  ;; pomodoro technique for org tasks
  (use-package org-pomodoro
    :ensure t)
  ;; fancy list bullets
  (use-package org-bullets
    :ensure t
    :config
    (add-hook 'org-mode-hook 'org-bullets-mode))
  ;; personal journal
  (use-package org-journal
    :ensure t
    :init
    (setq org-journal-dir "~/org/journal")
    (setq org-journal-enable-encryption t))

  :mode ("\\.\\(org\\|org_archive\\|txt\\)\\'" . org-mode)
  :bind (("C-c l" . org-store-link)
         ("C-c c" . org-capture)
         ("C-c a" . org-agenda)
         ("C-c b" . org-iswitchb)
         ("<f6>"  . org-agenda)
         ("<f7>"  . org-clock-goto)
         ("<f8>"  . org-clock-in)
         ("<f9>"  . org-pomodoro)))

;;; defuns

(defun my-comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)))

(defun my-insert-at-sign ()
  "Inserts an at sign into the buffer."
  (interactive)
  (insert "@"))

(defun my-insert-euro-sign ()
  "Inserts an euro sign into the buffer."
  (interactive)
  (insert "€"))

(defun my-toggle-fullscreen ()
  "Toggles the current window to full screen. Supports both OSX
and X11 environment. On OSX it does so using the 'old-style'
fullscreen."
  (interactive)
  (cond
   ((eq system-type 'darwin)
    (set-frame-parameter
     nil 'fullscreen
     (when (not (frame-parameter nil 'fullscreen)) 'fullboth)))
   ((eq window-system 'x)
    (x-send-client-message nil 0 nil "_NET_WM_STATE" 32
                           '(2 "_NET_WM_STATE_FULLSCREEN" 0)))
   (error "Unable to toggle fullscreen")))

(defun my-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.  Move
point to the first non-whitespace character on this line.  If
point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.  If ARG is not nil or 1, move forward
ARG - 1 lines first. If point reaches the beginning or end of the
buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))
  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))
  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

(defun my-rename-buffer-and-file ()
  "Rename current buffer and if the buffer is visiting a file, rename it too."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (rename-buffer (read-from-minibuffer "New name: " (buffer-name)))
      (let ((new-name (read-file-name "New name: " filename)))
        (cond
         ((vc-backend filename) (vc-rename-file filename new-name))
         (t
          (rename-file filename new-name t)
          (set-visited-file-name new-name t t)))))))

(defun my-delete-buffer-and-file ()
  "Kill the current buffer and deletes the file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (when filename
      (if (vc-backend filename)
          (vc-delete-file filename)
        (when (y-or-n-p (format "Are you sure you want to delete %s? " filename))
          (delete-file filename delete-by-moving-to-trash)
          (message "Deleted file %s" filename)
          (kill-buffer))))))

(bind-keys ("C-x ç"   . my-comment-or-uncomment-region-or-line)
           ("C-a"     . my-move-beginning-of-line)
           ("s-2"     . my-insert-at-sign)
           ("s-3"     . my-insert-euro-sign)
           ("<f5>"    . my-toggle-fullscreen)
           ("C-c r"   . my-rename-buffer-and-file)
           ("C-c D"   . my-delete-buffer-and-file)
           ("s-l"     . goto-line)
           ("C-c C-m" . execute-extended-command))

;; print the load time
(when window-system
  (add-hook 'after-init-hook
            (lambda ()
              (let ((elapsed (float-time (time-subtract (current-time)
                                                        emacs-start-time))))
                (message "init finished [%.3fs]" elapsed)))))
