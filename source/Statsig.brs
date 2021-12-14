function Statsig(task as Object)
    this = {
        "initialize": function(sdkKey as string, user as Object) as void
            m._task.sdkKey = sdkKey
            m._user = user
            m._statsig = StatsigClient(m._task, user)
            m._task.userAttributes = user.toEvaluationDictionary()
            m._task.control = "run"
        end function

        "load": function() as void
            m._statsig.loadValues(m._user, m._task.initializeValues)
        end function

        "checkGate": function(gate as string) as boolean
            if m._statsig = invalid then
                print "statsig is not initialized"
                return false
            end if
            return m._statsig.checkGate(gate)
        end function

        "getConfig": function(config as string) as object
            if m._statsig = invalid then
                print "statsig is not initialized"
                return DynamicConfig(config, {}, "")
            end if
            return m._statsig.getConfig(config)
        end function

        "getExperiment": function(experiment as string) as object
            if m._statsig = invalid then
                print "statsig is not initialized"
                return DynamicConfig(experiment, {}, "")
            end if
            return m._statsig.getExperiment(experiment)
        end function

        "logEvent": function(eventName as String, value as Dynamic, metadata as object) as void
            if m._statsig = invalid then
                print "statsig is not initialized"
                return
            end if
            m._statsig.logEvent(eventName, value, metadata)
        end function

        "shutdown": function() as void
            if m._statsig = invalid then
                print "statsig is not initialized"
                return
            end if
            m._statsig.flush()
        end function

        "updateUser": function(user as object) as void
            if m._statsig = invalid then
                print "statsig is not initialized"
                return
            end if
            m._user = user
            m._statsig.updateUser(user)
            m._task.userAttributes = user.toEvaluationDictionary()
            m._task.event = {name: "update_user"}
        end function

        _statsig: invalid
        _user: invalid
        _task: task
    }
    return this
end function