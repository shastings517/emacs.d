;; save start time
(defconst !/start-time (current-time))

;; use one folder for all save/history/cache files
(defconst !/savefile-dir (expand-file-name "savefile" user-emacs-directory))
(unless (file-exists-p !/savefile-dir)
  (make-directory !/savefile-dir))

;; third-party code not available on ELPA should reside in this folder
(defconst !/sitelisp-dir (expand-file-name "site-lisp" user-emacs-directory))

;; load 3rd party code from `site-lisp' folder
(add-to-list 'load-path !/sitelisp-dir t)

;; use a separate file for emacs customization settings
(defconst !/custom-file (expand-file-name "custom.el" user-emacs-directory))
(setq custom-file !/custom-file)

;; increase base garbace collection threshold and reduce garbage collections during init
(defconst !/gc-cons-threshold 20000000)
(setq gc-cons-threshold (* 128 1000 1000))
(add-hook 'after-init-hook
          (lambda () (setq gc-cons-threshold !/gc-cons-threshold)))

;;; setup `package'
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; `use-package' is not needed at runtime
(eval-when-compile
  (require 'use-package))

;; required for `use-package' :diminish
;; reduce modeline clutter
(use-package diminish
  :ensure t)

;; better emacs defaults
(use-package better-defaults
  :ensure t
  :config
  (setq visible-bell nil)
  ;; disable bell for commands
  (setq ring-bell-function
        (lambda ()
          (unless (memq this-command
                        '(isearch-abort abort-recursive-edit exit-minibuffer keyboard-quit helm-keyboard-quit keyboard-escape-quit))
            (ding)))))

;; start `server' if one isn't already running
(use-package server
  :config
  (unless (server-running-p) (server-start)))

;; configure `exec-path' from shell
(use-package exec-path-from-shell
  :ensure t
  :init
  (setq exec-path-from-shell-check-startup-files nil)
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-env "SSH_AGENT_PID")
  (exec-path-from-shell-copy-env "SSH_AUTH_SOCK"))

;; setup modifier keys on macOS
(when (memq window-system '(mac ns))
  (setq mac-right-option-modifier nil)
  (setq mac-command-modifier 'super)
  (setq mac-option-modifier 'meta)
  (setq ns-function-modifier 'hyper))

;; undo history as a tree
(use-package undo-tree
  :ensure t
  :diminish undo-tree-mode
  :init
  ;; autosave the undo-tree history
  (setq undo-tree-history-directory-alist
        `((".*" . ,temporary-file-directory)))
  (setq undo-tree-auto-save-history t)
  (setq undo-tree-visualizer-diff t)
  :config
  (global-undo-tree-mode))

;; unobtrusively trim trailing whitespace
(use-package ws-butler
  :ensure t
  :diminish ws-butler-mode
  :config
  (ws-butler-global-mode))

;; extensible vi layer
(use-package evil
  :ensure t
  :init
  (setq evil-want-C-i-jump nil)
  :config
  (evil-mode 1))

;; add minimal Vim keys to arbitrary modes
(use-package evil-evilified-state
  :after evil
  :config
  (evilified-state-evilify special-mode special-mode-map)
  (evilified-state-evilify help-mode help-mode-map)
  (evilified-state-evilify messages-buffer-mode messages-buffer-mode-map)
  ;; reload messages buffer mode to force new keymap
  (add-hook 'after-init-hook
            (lambda ()
              (with-current-buffer "*Messages*"
                (messages-buffer-mode)))))

;; `anzu' for `evil' mode
(use-package evil-anzu
  :ensure t
  :after evil)

;; comment code efficiently
(use-package evil-nerd-commenter
  :ensure t
  :after evil
  :commands evilnc-comment-or-uncomment-lines)

;; dark theme
(use-package dracula-theme
  :ensure t
  :config
  (load-theme 'dracula t))

;; interactive completion
(use-package helm
  :ensure t
  :diminish helm-mode
  :init
  (setq helm-autoresize-max-height 30
        helm-display-header-line nil
        helm-always-two-windows t
        helm-split-window-inside-p t
        helm-move-to-line-cycle-in-source t
        helm-ff-search-library-in-sexp t
        helm-ff-file-name-history-use-recentf t
        helm-comp-read-mode-line ""
        helm-read-file-name-mode-line-string ""
        helm-mode-line-string ""
        helm-adaptive-history-file (expand-file-name "helm-adaptive-history" !/savefile-dir))
  ;; enable fuzzy matching
  (setq helm-buffers-fuzzy-matching t
        helm-completion-in-region-fuzzy-match t
        helm-M-x-fuzzy-match t
        helm-apropos-fuzzy-match t
        helm-imenu-fuzzy-match t
        helm-lisp-fuzzy-completion t
        helm-locate-fuzzy-match t
        helm-mode-fuzzy-match t
        helm-recentf-fuzzy-match t
        helm-semantic-fuzzy-match t)
  :config
  (require 'helm-config)
  (helm-mode 1)
  (helm-autoresize-mode 1)
  (helm-adaptive-mode 1))

;; fuzzier matching for helm
(use-package helm-flx
  :ensure t
  :after helm
  :config
  (helm-flx-mode +1))

;; numbered window shortcuts
(use-package winum
  :ensure t
  :init
  (setq-default winum-keymap nil)
  :config
  (winum-mode))

;; project interaction library
(use-package projectile
  :ensure t
  :after helm
  :diminish projectile-mode
  :init
  (setq projectile-completion-system 'helm
        projectile-cache-file (expand-file-name "projectile.cache" !/savefile-dir)
        projectile-known-projects-file (expand-file-name "projectile-bookmarks.eld" !/savefile-dir)
        projectile-enable-caching t)
  :config
  (projectile-mode))

;; `projectile' integration for `helm'
(use-package helm-projectile
  :ensure t
  :after helm projectile
  :init
  (setq helm-projectile-fuzzy-match t)
  :config
  (helm-projectile-on))

;; `helm' interface for `ag'
(use-package helm-ag
  :ensure t
  :after helm-projectile
  :commands helm-do-ag)

;; perspectives for emacs
(use-package persp-mode
  :ensure t
  :diminish persp-mode
  :init
  (setq wg-morph-on nil ;; switch off animation
        persp-add-buffer-on-after-change-major-mode t
        persp-auto-resume-time -1
        persp-autokill-buffer-on-remove 'kill-weak
        persp-save-dir (expand-file-name "persp-confs/" !/savefile-dir))
  (add-hook 'after-init-hook (lambda () (persp-mode 1)))
  :config
  (defvar !//persp-last-selected-perspective persp-nil-name
    "Previously selected perspective.")

  (defun !//persp-save-last-selected-perspective (_ _ &optional _)
    (setq !//persp-last-selected-perspective persp-last-persp-name))
  (advice-add 'persp-activate :before #'!//persp-save-last-selected-perspective))

;; the best git client ever
(use-package magit
  :ensure t
  :commands magit-status
  :init
  (setq magit-section-visibility-indicator nil)
  :config
  (defun !/projectile-invalidate-cache (&rest _args)
    ;; We ignore the args to `magit-checkout'.
    (projectile-invalidate-cache nil))
  (advice-add 'magit-checkout
              :after #'!/projectile-invalidate-cache)
  (advice-add 'magit-branch-and-checkout ; This is `b c'.
              :after #'!/projectile-invalidate-cache))

;; highlight uncommitted changes on the left side of the window
(use-package git-gutter
  :ensure t
  :diminish git-gutter-mode
  :init
  (setq git-gutter:window-width 1
        git-gutter:update-interval 2
        git-gutter:modified-sign "│"
        git-gutter:added-sign "│"
        git-gutter:deleted-sign "│")
  :config
  (set-face-foreground 'git-gutter:modified "#ffb86c") ; dracula rainbow-5
  (set-face-foreground 'git-gutter:added "#50fa7b") ; dracula rainbow-6
  (set-face-foreground 'git-gutter:deleted "#ff5555") ; dracula rainbow-9
  (add-to-list 'git-gutter:update-hooks 'focus-in-hook)
  (add-hook 'magit-post-refresh-hook 'git-gutter:update-all-windows)
  (global-git-gutter-mode t))

;; `evil' keys for `magit'
(use-package evil-magit
  :ensure t
  :after evil magit)

(use-package git-timemachine
  :ensure t
  :after magit
  :config
  (evil-make-overriding-map git-timemachine-mode-map 'normal)
  ;; force update evil keymaps after git-timemachine-mode loaded
  (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))

;; display available keybindings in popup
(use-package which-key
  :ensure t
  :diminish which-key-mode
  :config
  (which-key-mode))

;; fancy mode-line icons
(use-package all-the-icons
  :ensure t)

;; store all backup and autosave files in the tmp dir
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; store `auto-save-list' backup file mapping in `savefile' dir
(setq auto-save-list-file-prefix
      (expand-file-name "auto-save-list/.saves-" !/savefile-dir))

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

;; disable startup screen
(setq inhibit-startup-screen t)

;; highlight current line
(global-hl-line-mode 1)

;; internationalization
(prefer-coding-system 'utf-8)

;; revert buffers automatically (also non-file buffers)
(use-package autorevert
  :diminish auto-revert-mode
  :init
  (setq global-auto-revert-non-file-buffers t)
  :config
  (global-auto-revert-mode t))

;; clean up obsolete buffers
(use-package midnight)

;; meaningful names for buffers with the same name
(use-package uniquify
  :init
  (setq uniquify-buffer-name-style 'forward)
  (setq uniquify-separator "/")
  ;; don't muck with special buffers
  (setq uniquify-ignore-buffers-re "^\\*"))

;; `saveplace' remembers your location in a file when saving files
(use-package saveplace
  :init
  (setq save-place-file (expand-file-name "saveplace" !/savefile-dir))
  :config
  (save-place-mode +1)
  ;; activate it for all buffers
  (setq-default save-place t))

;; `savehist' keeps track of some history
(use-package savehist
  :init
  (setq savehist-additional-variables
        ;; search entries
        '(search-ring regexp-search-ring extended-command-history)
        ;; save every minute
        savehist-autosave-interval 60
        ;; keep the home clean
        savehist-file (expand-file-name "savehist" !/savefile-dir))
  :config
  (savehist-mode +1))

;; save recent files
(use-package recentf
  :init
  (setq recentf-save-file (expand-file-name "recentf" !/savefile-dir)
        recentf-max-saved-items 500
        recentf-max-menu-items 15
        ;; disable recentf-cleanup on Emacs start, because it can cause
        ;; problems with remote files
        recentf-auto-cleanup 'never)
  (defun !//recentf-exclude-p (file)
    "A predicate to decide whether to exclude FILE from recentf."
    (let ((file-dir (file-truename (file-name-directory file))))
      (-any-p (lambda (dir)
                (string-prefix-p dir file-dir))
              (mapcar 'file-truename (list !/savefile-dir package-user-dir)))))
  :config
  (add-to-list 'recentf-exclude '!//recentf-exclude-p)
  (recentf-mode +1))

;; smoother scrolling
(setq scroll-step 1
      scroll-conservatively 10000
      auto-window-vscroll nil)

;; disabled right fringe and small left fringe
(when (fboundp 'fringe-mode)
  (fringe-mode '(4 . 0)))

;; follow symlinks without asking
(setq vc-follow-symlinks t)

;; set default fonts
(use-package spacemacs-fonts-support
  :config
  (spacemacs/set-default-font
   '("Source Code Pro"
     :size 13
     :weight normal
     :width normal))

  (when (memq window-system '(mac ns))
    ;; Use the OS X Emoji font for Emoticons
    (when (fboundp 'set-fontset-font)
      (set-fontset-font "fontset-default"
                        '(#x1F600 . #x1F64F)
                        (font-spec :name "Apple Color Emoji") nil 'prepend))))

;; customize mode-line
(defun !//modeline-segment-git-vc ()
  (let ((branch (mapconcat 'concat (cdr (split-string vc-mode "[:-]")) "-")))
    (concat
     (propertize (format " %s" (all-the-icons-octicon "git-branch"))
                 'face `(:height 1 :family ,(all-the-icons-octicon-family))
                 'display '(raise 0))
     (propertize (format " %s" branch)))))

(defun !//modeline-segment-svn-vc ()
  (let ((revision (cadr (split-string vc-mode "-"))))
    (concat
     (propertize (format " %s" (all-the-icons-faicon "cloud"))
                 'face `(:height 1)
                 'display '(raise 0))
     (propertize (format " %s" revision) 'face `(:height 0.9)))))

(defvar !//mode-line-vc
  '(:eval (when vc-mode
            (cond
             ((string-match "Git[:-]" vc-mode) (!//modeline-segment-git-vc))
             ((string-match "SVN-" vc-mode) (!//modeline-segment-svn-vc))
             (t (format "%s" vc-mode))))
          face mode-line-directory)
  "Formats the current directory.")

(defvar !//mode-line-persp
  '(:eval (when (get-current-persp)
            (propertize (format "[%s] " (persp-name (get-current-persp)))))))

(setq evil-mode-line-format '(before . mode-line-position))
(setq-default mode-line-format
              (list
               '(:eval (propertize (format " %s" (winum-get-number-string))))
               " "
               mode-line-mule-info
               mode-line-modified
               mode-line-frame-identification
               mode-line-buffer-identification
               "  "
               mode-line-position
               "  "
               !//mode-line-persp
               !//mode-line-vc
               "   "
               mode-line-modes))

(set-face-background 'mode-line-inactive "#373844")

;; increase mode-line width
(custom-set-faces
 `(mode-line-inactive ((t (:background ,(face-attribute 'mode-line-inactive :background)
                                       :foreground ,(face-attribute 'mode-line-inactive :foreground)
                                       :box (:line-width 4 :color ,(face-attribute 'mode-line-inactive :background))))))
 `(mode-line ((t (:background ,(face-attribute 'mode-line :background)
                              :foreground ,(face-attribute 'mode-line :foreground)
                              :box (:line-width 4 :color ,(face-attribute 'mode-line :background)))))))

;; display the current column in mode-line
(setq column-number-mode t)

;; set default width to 100 columns
(setq-default fill-column 100)

;; set tab size to 4
(setq-default tab-width 4)

;; zoom frame font size
(use-package zoom-frm
  :commands zoom-frm-in zoom-frm-out zoom-frm-unzoom)

;; file tree
(use-package neotree
  :ensure t
  :init
  (setq neo-theme (if (display-graphic-p) 'icons 'arrow)))

;; enhanced `list-packages'
(use-package paradox
  :ensure t
  :commands paradox-list-packages
  :init
  (setq paradox-github-token t)
  :config
  (evilified-state-evilify paradox-menu-mode paradox-menu-mode-map))

;; show argument list/type information in the modeline
(use-package eldoc
  :diminish eldoc-mode)

;; in-buffer completion
(use-package company
  :ensure t
  :diminish company-mode
  :init
  (setq company-minimum-prefix-length 2
        company-selection-wrap-around t
        company-tooltip-align-annotations t)
  :config
  (add-hook 'after-init-hook 'global-company-mode))

;; semantic region expansion
(use-package expand-region
  :ensure t
  :commands er/expand-region
  :init
  (setq-default
   expand-region-contract-fast-key "V"
   expand-region-reset-fast-key "r"))

;; highlight TODO keywords
(use-package hl-todo
  :ensure t
  :config
  (global-hl-todo-mode))

;; use project-defined editor settings
(use-package editorconfig
  :ensure t
  :diminish editorconfig-mode
  :config
  (editorconfig-mode 1))

;; emacs support for the Language Server Protocol
(use-package lsp-mode
  :ensure t
  :disabled t)

;; `company' backend for `lsp-mode'
(use-package company-lsp
  :ensure t
  :after company lsp-mode
  :init
  (push 'company-lsp company-backends))

;; `markdown' mode
(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))

;; `scala' programming mode
(use-package scala-mode
  :ensure t
  :mode ("\\.\\(scala\\|sbt\\)\\'" . scala-mode))

;; `yaml' mode
(use-package yaml-mode
  :ensure t
  :mode (("\\.\\(yml\\|yaml\\)\\'" . yaml-mode)
         ("Procfile\\'" . yaml-mode)))

;; `solidity' mode
(use-package solidity-mode
  :ensure t
  :mode ("\\.sol\\'" . solidity-mode))

;; `go' mode
(use-package go-mode
  :ensure t
  :mode ("\\.go\\'" . go-mode))

;; `typescript' mode
(use-package typescript-mode
  :ensure t
  :mode ("\\.ts\\'" . typescript-mode))

;; `typescript' IDE integration with `tsserver'
(use-package tide
  :ensure t
  :after typescript-mode
  :hook ((typescript-mode . tide-setup)
         (typescript-mode . tide-hl-identifier-mode)
         (before-save . tide-format-before-save)))

;; `javascript' mode
(use-package js2-mode
  :ensure t
  :mode ("\\.js\\'" . js2-mode)
  :init
  (setq js2-strict-trailing-comma-warning nil)
  (add-hook 'js2-mode-hook
            (lambda ()
              (make-local-variable 'js-indent-level)
              (setq js-indent-level 2))))

;; `json' mode
(use-package json-mode
  :ensure t
  :mode ("\\.json\\'" . json-mode)
  :init
  (add-hook 'json-mode-hook
            (lambda ()
              (make-local-variable 'js-indent-level)
              (setq js-indent-level 2))))

;; interactive lisp macro expansion
(use-package macrostep
  :ensure t
  :diminish macrostep-mode
  :commands macrostep-expand)

;; interact with HTTP APIs
(use-package restclient
  :ensure t
  :mode ("\\.http\\'" . restclient-mode))

;; `rust' programming mode
(use-package rust-mode
  :ensure t
  :mode ("\\.rs\\'" . rust-mode))

;; code completion for `rust'
(use-package racer
  :ensure t
  :after rust-mode
  :diminish racer-mode
  :init
  (add-hook 'rust-mode-hook #'racer-mode)
  (add-hook 'racer-mode-hook (lambda () (setq eldoc-documentation-function nil))))

;; `lsp-mode' client using the Rust Language Server
(use-package lsp-rust
  :ensure t
  :disabled t
  :after lsp-mode
  :init
  (add-hook 'rust-mode-hook #'lsp-rust-enable))

;; `toml' support for `cargo' files
(use-package toml-mode
  :ensure t
  :mode ("\\.toml\\'" . toml-mode))

(use-package org
  :mode ("\\.\\(org\\|org_archive\\|txt\\)\\'" . org-mode)
  :init
  (setq
   ;; log time when task is finished
   org-log-done 'time
   ;; create a logbook entry
   org-log-into-drawer t
   ;; org directory and agenda files
   org-directory "~/org"
   org-agenda-files (quote ("~/org/todo.org"
                            "~/org/projects"
                            "~/org/journal"))
   ;; include numeric filenames in regexp (for journal files)
   org-agenda-file-regexp "'\\`[^.].*\\.org'\\|[0-9]+"
   ;; org keywords and faces
   org-todo-keywords (quote
                      ((sequence "TODO(t)" "STARTED(s)" "|" "DONE(d)")
                       (sequence "WAITING(w@/!)" "HOLD(h@/!)" "|" "CANCELED(c@/!)")))
   ;; dracula-themed faces
   org-todo-keyword-faces (quote
                           (("TODO" :foreground "#ff5555" :weight bold)
                            ("STARTED" :foreground "#8be9fd" :weight bold)
                            ("DONE" :foreground "#50fa7b" :weight bold)
                            ("WAITING" :foreground "#ffb86c" :weight bold)
                            ("HOLD" :foreground "#bd93f9" :weight bold)
                            ("CANCELED" :foreground "#50fa7b" :weight bold)))
   ;; state triggers
   org-todo-state-tags-triggers (quote
                                 (("CANCELED" ("CANCELED" . t))
                                  ("WAITING"  ("WAITING"  . t))
                                  ("HOLD"     ("WAITING"  . t) ("HOLD" . t))
                                  (done       ("WAITING")      ("HOLD"))
                                  ("TODO"     ("WAITING")      ("CANCELED") ("HOLD"))
                                  ("STARTED"  ("WAITING")      ("CANCELED") ("HOLD"))
                                  ("DONE"     ("WAITING")      ("CANCELED") ("HOLD"))))
   ;; use fast todo selection
   org-use-fast-todo-selection t
   org-treat-S-cursor-todo-selection-as-state-change nil
   ;; handle empty lines
   org-cycle-separator-lines 0
   org-blank-before-new-entry (quote ((heading)
                                      (plain-list-item . auto)))
   ;; targets complete directly with ido
   org-outline-path-complete-in-steps nil
   ;; use ido for both buffer and file completion and ido-everywhere to t
   org-completion-use-ido t)
  :config
  (set-face-attribute 'org-level-1 nil :height 1.0)
  (set-face-attribute 'org-level-2 nil :height 1.0))

(use-package org-bullets
  :ensure t
  :after org
  :init
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

;; convenient key definitions
(use-package general
  :ensure t
  :config
  (general-define-key
   "M-/" 'hippie-expand
   "C-;" 'hippie-expand)

  (general-define-key
   :keymaps '(magit-status-mode-map magit-diff-mode-map)
   "SPC" nil)

  (general-define-key
   :keymaps 'minibuffer-local-map
   "<escape>" 'keyboard-escape-quit)

  (general-define-key
   :keymaps 'helm-map
   "<tab>" 'helm-execute-persistent-action ;; rebind tab to run persistent action
   "C-i" 'helm-execute-persistent-action ;; make TAB works in terminal
   "C-z" 'helm-select-action ;; list actions using C-z
   "C-j" 'helm-next-line
   "C-k" 'helm-previous-line
   "C-l" (kbd "RET")
   "<escape>" 'helm-keyboard-quit)

  (general-define-key
   :keymaps 'company-active-map
   "C-j" 'company-select-next
   "C-k" 'company-select-previous
   "C-l" 'company-complete-selection)

  (general-define-key
   :keymaps 'emacs-lisp-mode-map
   :states '(normal visual insert emacs evilified)
   :prefix ","
   :non-normal-prefix "M-,"
   "e" '(:ignore t :which-key "emacs-lisp")
   "er" 'eval-region
   "ee" 'macrostep-expand)

  (general-define-key
   :keymaps 'rust-mode-map
   :states '(normal visual insert emacs evilified)
   :prefix ","
   :non-normal-prefix "M-,"
   "." 'racer-find-definition
   "," 'pop-tag-mark
   "d" 'racer-describe)

  (general-define-key
   :keymaps 'macrostep-keymap
   :states 'normal
   "q" 'macrostep-collapse-all)

  (general-define-key
   :states '(normal visual insert emacs evilified)
   :prefix "SPC"
   :non-normal-prefix "M-SPC"

   "SPC" '(helm-M-x :which-key "M-x")
   "TAB" '!/alternate-buffer

   ;; window numbers
   "0" 'winum-select-window-0-or-10
   "1" 'winum-select-window-1
   "2" 'winum-select-window-2
   "3" 'winum-select-window-3
   "4" 'winum-select-window-4
   "5" 'winum-select-window-5
   "6" 'winum-select-window-6
   "7" 'winum-select-window-7
   "8" 'winum-select-window-8
   "9" 'winum-select-window-9

   "b" '(:ignore t :which-key "buffers")
   "bb" '!/helm-persp-mini
   "bB" 'helm-mini
   "bl" 'helm-buffers-list
   "bd" 'kill-this-buffer
   "bs" '!/switch-to-scratch-buffer
   "bm" '!/switch-to-messages-buffer

   "c" 'evilnc-comment-or-uncomment-lines
   ";" 'evilnc-comment-or-uncomment-lines

   "f" '(:ignore t :which-key "files")
   "ff" '(helm-find-files :which-key "find-files")
   "fs" 'save-buffer
   "fr" 'helm-recentf
   "fD" '!/delete-current-buffer-file
   "fR" '!/rename-current-buffer-file

   "g" '(:ignore t :which-key "git")
   "gs" 'magit-status

   "h" '(:ignore t :which-key "help")
   "ha" '(helm-apropos :which-key "apropos")
   "hi" '(helm-info-at-point :which-key "describe-symbol")
   "hf" 'describe-function
   "hv" 'describe-variable
   "hk" 'describe-key

   "l" '(:ignore t :which-key "layouts")
   "l TAB" '(!/alternate-layout :which-key "alternate-layout")
   "ln" '(persp-add-new :which-key "new-layout")
   "ll" '(persp-switch :which-key "list-layouts")
   "lc" '(persp-kill-without-buffers :which-key "close-layout")
   "lk" '(persp-kill :which-key "kill-layout")
   "lb" '(:ignore t :which-key "layout buffers")
   "lba" 'persp-add-buffer
   "lbr" 'persp-remove-buffer

   "p" '(:ignore t :which-key "projects")
   "p SPC" 'helm-projectile
   "pb" 'helm-projectile-switch-to-buffer
   "pd" 'helm-projectile-find-dir
   "pp" 'helm-projectile-switch-project
   "pf" 'helm-projectile-find-file
   "ps" '!/helm-project-do-rg
   "pl" '!/helm-layout-switch-project
   "pi" 'projectile-invalidate-cache

   "r" '(:ignore t :which-key "registers")
   "rl" 'helm-resume
   "ry" 'helm-show-kill-ring
   "rm" 'helm-all-mark-rings

   "s" '(:ignore t :which-key "search")
   "sf" 'helm-find
   "ss" '!/helm-files-do-rg
   "sp" '!/helm-project-do-rg

   "w" '(:ignore t :which-key "windows")
   "w TAB" '!/alternate-window
   "w2" '!/window-layout-double-columns
   "w3" '!/window-layout-triple-columns
   "wb" '!/switch-to-minibuffer-window
   "wd" '!/delete-window
   "wo" 'other-frame
   "ws" 'split-window-below
   "w-" 'split-window-below
   "wv" 'split-window-right
   "w/" 'split-window-right
   "w=" 'balance-windows
   "ww" '!/alternate-window

   "u" 'universal-argument
   "v" 'er/expand-region

   "z" '(:ignore t :which-key "zoom")
   "z+" 'zoom-frm-in
   "z=" 'zoom-frm-in
   "z-" 'zoom-frm-out
   "z0" 'zoom-frm-unzoom))

(defun !/alternate-buffer (&optional window)
  "Switch back and forth between current and last buffer in the
current window."
  (interactive)
  (let ((current-buffer (window-buffer window)))
    ;; if no window is found in the windows history, `switch-to-buffer' will
    ;; default to calling `other-buffer'.
    (switch-to-buffer
     (cl-find-if (lambda (buffer)
                   (not (eq buffer current-buffer)))
                 (mapcar #'car (window-prev-buffers window))))))

(defun !/alternate-window ()
  "Switch back and forth between current and last window in the
current frame."
  (interactive)
  (let (;; switch to first window previously shown in this frame
        (prev-window (get-mru-window nil t t)))
    ;; Check window was not found successfully
    (unless prev-window (user-error "Last window not found."))
    (select-window prev-window)))

(defun !/alternate-layout ()
  "Switch back and forth between current and last layout in the
current frame."
  (interactive)
  (unless (eq 'non-existent
              (gethash !//persp-last-selected-perspective
                       *persp-hash* 'non-existent))
    (persp-switch !//persp-last-selected-perspective)))

(defun !/switch-to-scratch-buffer (&optional arg)
  "Switch to the `*scratch*' buffer, creating it first if needed.
If prefix argument ARG is given, switch to it in an other, possibly new window."
  (interactive "P")
  (let ((exists (get-buffer "*scratch*")))
    (if arg
        (switch-to-buffer-other-window (get-buffer-create "*scratch*"))
      (switch-to-buffer (get-buffer-create "*scratch*")))))

(defun !/switch-to-messages-buffer (&optional arg)
  "Switch to the `*Messages*' buffer.
If prefix argument ARG is given, switch to it in an other, possibly new window."
  (interactive "P")
  (with-current-buffer (messages-buffer)
    (goto-char (point-max))
    (if arg
        (switch-to-buffer-other-window (current-buffer))
      (switch-to-buffer (current-buffer)))))

(defun !//package-used-p (package)
  "Return `t' if PACKAGE is used (i.e. it is available), `nil' otherwise."
  (when (require package nil 'noerror)
    t))

(defun !/delete-current-buffer-file ()
  "Removes file connected to current buffer and kills buffer."
  (interactive)
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (ido-kill-buffer)
      (when (yes-or-no-p "Are you sure you want to delete this file? ")
        (delete-file filename t)
        (kill-buffer buffer)
        (when (and (!//package-used-p 'projectile)
                   (projectile-project-p))
          (call-interactively #'projectile-invalidate-cache))
        (message "File '%s' successfully removed" filename)))))

(defun !/rename-current-buffer-file (&optional arg)
  "Rename the current buffer and the file it is visiting. If the
buffer isn't visiting a file, ask if it should be saved to a
file, or just renamed. If called without a prefix argument, the
prompt is initialized with the current filename."
  (interactive "P")
  (let* ((name (buffer-name))
         (filename (buffer-file-name)))
    (if (and filename (file-exists-p filename))
        ;; the buffer is visiting a file
        (let* ((dir (file-name-directory filename))
               (new-name (read-file-name "New name: " (if arg dir filename))))
          (cond ((get-buffer new-name)
                 (error "A buffer named '%s' already exists!" new-name))
                (t
                 (let ((dir (file-name-directory new-name)))
                   (when (and (not (file-exists-p dir))
                              (yes-or-no-p
                               (format "Create directory '%s'?" dir)))
                     (make-directory dir t)))
                 (rename-file filename new-name 1)
                 (rename-buffer new-name)
                 (set-visited-file-name new-name)
                 (set-buffer-modified-p nil)
                 (when (fboundp 'recentf-add-file)
                   (recentf-add-file new-name)
                   (recentf-remove-if-non-kept filename))
                 (when (and (!//package-used-p 'projectile)
                            (projectile-project-p))
                   (call-interactively #'projectile-invalidate-cache))
                 (message "File '%s' successfully renamed to '%s'"
                          name (file-name-nondirectory new-name)))))
      ;; the buffer is not visiting a file
      (let ((key))
        (while (not (memq key '(?s ?r)))
          (setq key (read-key (propertize
                               (format
                                (concat "Buffer '%s' is not visiting a file: "
                                        "[s]ave to file or [r]ename buffer?")
                                name) 'face 'minibuffer-prompt)))
          (cond ((eq key ?s)            ; save to file
                 ;; this allows for saving a new empty (unmodified) buffer
                 (unless (buffer-modified-p) (set-buffer-modified-p t))
                 (save-buffer))
                ((eq key ?r)            ; rename buffer
                 (let ((new-name (read-string "New buffer name: ")))
                   (while (get-buffer new-name)
                     ;; ask to rename again, if the new buffer name exists
                     (if (yes-or-no-p
                          (format (concat "A buffer named '%s' already exists: "
                                          "Rename again?") new-name))
                         (setq new-name (read-string "New buffer name: "))
                       (keyboard-quit)))
                   (rename-buffer new-name)
                   (message "Buffer '%s' successfully renamed to '%s'"
                            name new-name)))
                ;; ?\a = C-g, ?\e = Esc and C-[
                ((memq key '(?\a ?\e)) (keyboard-quit))))))))

(defun !/delete-window (&optional arg)
  "Delete the current window.
If the universal prefix argument is used then kill the buffer too."
  (interactive "P")
  (if (equal '(4) arg)
      (kill-buffer-and-window)
    (delete-window)))

(defun !/window-layout-double-columns ()
  "Set the window layout to double columns."
  (interactive)
  (delete-other-windows)
  (split-window-right))

(defun !/window-layout-triple-columns ()
  "Set the window layout to triple columns."
  (interactive)
  (delete-other-windows)
  (dotimes (i 2) (split-window-right))
  (balance-windows))

(defun !/switch-to-minibuffer-window ()
  "Switch to minibuffer window (if active)."
  (interactive)
  (when (active-minibuffer-window)
    (select-window (active-minibuffer-window))))

(defun !/helm-layout-switch-project (arg)
  (interactive "P")
  (helm
   :sources
   (helm-build-in-buffer-source "*Helm Switch Project Layout*"
     :data (lambda ()
             (if (projectile-project-p)
                 (cons (abbreviate-file-name (projectile-project-root))
                       (projectile-relevant-known-projects))
               projectile-known-projects))
     :fuzzy-match helm-projectile-fuzzy-match
     :mode-line helm-read-file-name-mode-line-string
     :action '(("Switch to Project Perspective" .
                (lambda (project)
                  (let ((persp-reset-windows-on-nil-window-conf t))
                    (persp-switch (file-name-nondirectory (directory-file-name project)))
                    (let ((projectile-completion-system 'helm))
                      (projectile-switch-project-by-name project)))))))
   :buffer "*Helm Projectile Layouts*"))

(defun !/helm-persp-mini ()
  "As `helm-mini' but restricts visible buffers by perspective."
  (interactive)
  (with-persp-buffer-list ()
                          (helm-mini)))

(defun !/helm-files-do-rg (&optional dir)
  "Search in files with `rg'."
  (interactive)
  ;; --line-number forces line numbers (disabled by default on windows)
  ;; no --vimgrep because it adds column numbers that wgrep can't handle
  ;; see https://github.com/syl20bnr/spacemacs/pull/8065
  (let ((helm-ag-base-command "rg --smart-case --no-heading --color never --line-number --max-columns 150"))
    (helm-do-ag dir)))

(defun !/helm-project-do-rg ()
  "Search in current project with `rg'."
  (interactive)
  (let ((dir (projectile-project-root)))
    (if dir
        (!/helm-files-do-rg dir)
      (message "error: Not in a project."))))

;; load emacs customization settings
(if (file-exists-p custom-file)
    (load custom-file))

;; print init time
(add-hook 'after-init-hook
          (lambda ()
            (let ((elapsed (float-time (time-subtract (current-time)
                                                      !/start-time))))
              (message "init finished [%.3fs]" elapsed)))
          t)
