(use-modules
 (gnu packages)
 (gnu packages web)
 (gnu packages tls)
 (gnu packages autotools)
 (gnu packages textutils)  
 (gnu packages base)
 (gnu packages compression)
 (gnu packages gnupg)
 (gnu packages libevent)
 (gnu packages pkg-config)
 (gnu packages telegram)
 (gnu packages readline)
 (gnu packages python)
 (gnu packages lua)
 (gnu packages perl)
 ((dzi packages telegram) #:select (tgl))
 ((gnu packages telegram) #:select (tl-parser))
 ((guix licenses) #:prefix license:)
 (guix packages)
 (guix git-download)
 (guix gexp)
 (guix build-system gnu))

(define %source-dir (dirname (current-filename)))

(define telegram-cli
  (package
      (name "telegram-cli")
      (version "git")
      (source (local-file %source-dir
                          #:recursive? #t
                          #:select? (git-predicate %source-dir)))
      (build-system gnu-build-system)
      (arguments
       `(#:tests? #f                    ; No target
         #:imported-modules
         ((guix build copy-build-system)
          ,@%gnu-build-system-modules)
         #:modules
         (((guix build copy-build-system)
           #:prefix copy:)
          (guix build gnu-build-system)
          (guix build utils))
         #:configure-flags
         (list
          ;; Use gcrypt instead of openssl.
          "--disable-openssl")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'trigger-bootstrap
             (lambda _
               (delete-file "configure")
               #t))
           (add-after 'trigger-bootstrap 'patch-tgl-and-tlparser
             (lambda* (#:key inputs #:allow-other-keys)
               (for-each delete-file
                         (list
                          "Makefile.tgl"
                          "Makefile.tl-parser"))
               (substitute* "Makefile.in"
                 (("include \\$\\{srcdir\\}/Makefile\\.tl-parser")
                  "")
                 (("include \\$\\{srcdir\\}/Makefile\\.tgl")
                  "")
                 (("-I\\$\\{srcdir\\}/tgl")
                  (string-append "-I" (assoc-ref inputs "tgl")
                                 "/include/tgl"))
                 (("AUTO=auto")
                  (string-append "AUTO=" (assoc-ref inputs "tgl")
                                 "/include/tgl/auto"))
                 (("LIB=libs")
                  (string-append "LIB=" (assoc-ref inputs "tgl")
                                 "/lib/tgl")))
               #t))
           (replace 'install
             (lambda args
               (apply (assoc-ref copy:%standard-phases 'install)
                      #:install-plan
                      '(("bin" "bin")
                        ("." "etc/telegram-cli"
                         #:include-regexp ("\\.pub$")
                         #:exclude ("tg-server.pub")))
                      args))))))
      (native-inputs
       (list autoconf automake libtool pkg-config))
      (inputs
       (list jansson
             libconfig
             libevent
             libgcrypt
             lua
             openssl
             perl
             python
             readline
             tgl
             tl-parser
             zlib))
      (synopsis "Telegram Messenger CLI")
      (description "TG is the command-line interface for Telegram Messenger.")
      (home-page "https://github.com/vysheng/tg")
      (license license:gpl2+)))

telegram-cli
