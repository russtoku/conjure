(local {: autoload} (require :conjure.nfnl.module))
(local a (autoload :conjure.aniseed.core))
(local str (autoload :conjure.aniseed.string))
(local stdio (autoload :conjure.remote.stdio))
(local config (autoload :conjure.config))
(local mapping (autoload :conjure.mapping))
(local client (autoload :conjure.client))
(local log (autoload :conjure.log))
(local ts (autoload :conjure.tree-sitter))

(config.merge
  {:client
   {:r
    {:stdio
     {:command "R --vanilla --interactive --quiet"
      :prompt_pattern "> "
      :delay-stderr-ms 16}}}})

(when (config.get-in [:mapping :enable_defaults])
  (config.merge
    {:client
     {:r
      {:stdio
       {:mapping {:start "cs"
                  :stop "cS"
                  :interrupt "ei"}}}}}))

(local cfg (config.get-in-fn [:client :r :stdio]))
(local state (client.new-state #(do {:repl nil})))
(local buf-suffix ".r")
(local comment-prefix "# ")
(local form-node? ts.node-surrounded-by-form-pair-chars?)

(fn with-repl-or-warn [f _]
  (let [repl (state :repl)]
    (if repl
      (f repl)
      (log.append [(.. comment-prefix "No REPL running")]))))

(fn unbatch [msgs]
  {:out (->> msgs
          (a.map #(or (a.get $1 :out) (a.get $1 :err)))
          (str.join ""))})

(fn format-msg [msg]
  (->> (-> msg
           (a.get :out)
           ; (string.gsub "^%s*" "")
           ; (string.gsub "%s+%d+%s*$" "")
           (str.split "\n"))
       (a.map
         (fn [line]
           (if
             (not (cfg [:value_prefix_pattern]))
             line

             (string.match line (cfg [:value_prefix_pattern]))
             (string.gsub line (cfg [:value_prefix_pattern]) "")

             (.. comment-prefix "(out) " line))))
       (a.filter #(not (str.blank? $1)))))

(fn eval-str [opts]
  (with-repl-or-warn
    (fn [repl]
      (repl.send
        (.. opts.code "\n")
        (fn [msgs]
          (let [msgs (-> msgs unbatch format-msg)]
            (opts.on-result (a.last msgs))
            (log.append msgs)))
        {:batch? true}))))

(fn eval-file [opts]
  (eval-str (a.assoc opts :code (.. "(load \"" opts.file-path "\")"))))

(fn display-repl-status [status]
  (log.append
    [(.. comment-prefix
         (cfg [:command])
         " (" (or status "no status") ")")]
    {:break? true}))

(fn stop []
  (let [repl (state :repl)]
    (when repl
      (repl.destroy)
      (display-repl-status :stopped)
      (a.assoc (state) :repl nil))))

(fn start []
  (if (state :repl)
    (log.append [(.. comment-prefix "Can't start, REPL is already running.")
                 (.. comment-prefix "Stop the REPL with "
                     (config.get-in [:mapping :prefix])
                     (cfg [:mapping :stop]))]
                {:break? true})
    (a.assoc
      (state) :repl
      (stdio.start
        {:prompt-pattern (cfg [:prompt_pattern])
         :cmd (cfg [:command])

         :on-success
         (fn []
           (display-repl-status :started))

         :on-error
         (fn [err]
           (display-repl-status err))

         :on-exit
         (fn [code signal]
           (when (and (= :number (type code)) (> code 0))
             (log.append [(.. comment-prefix "process exited with code " code)]))
           (when (and (= :number (type signal)) (> signal 0))
             (log.append [(.. comment-prefix "process exited with signal " signal)]))
           (stop))

         :on-stray-output
         (fn [msg]
           (log.append (format-msg msg)))}))))

(fn interrupt []
  (with-repl-or-warn
    (fn [repl]
      (log.append [(.. comment-prefix " Sending interrupt signal.")] {:break? true})
      (repl.send-signal :sigint))))

(fn on-load []
  (start))

(fn on-filetype []
  (mapping.buf
    :RStart (cfg [:mapping :start])
    start
    {:desc "Start the R REPL"})

  (mapping.buf
    :RStop (cfg [:mapping :stop])
    stop
    {:desc "Stop the R REPL"})

  (mapping.buf
    :RInterrupt (cfg [:mapping :interrupt])
    interrupt
    {:desc "Interrupt the R REPL"}))

(fn on-exit []
  (stop))

{: buf-suffix
 : comment-prefix
 : form-node?
 : unbatch
 : format-msg
 : eval-str
 : eval-file
 : stop
 : start
 : interrupt
 : on-load
 : on-filetype
 : on-exit }
