function LogEvent(name as string) as object
    return {
        "setValue": function(value as dynamic) as void
            m._value = value
        end function

        "setMetadata": function(metadata as object) as void
            m._metadata = metadata
        end function

        "setUser": function(user as object) as void
            m._user = user
        end function

        "toJson": function() as object
            payload = {
                "eventName": m._name
                value: m._value
                metadata: m._metadata
                time: m._time
                user: m._user
            }
            if (m._secondary_exposures <> invalid) then
                payload["secondaryExposures"] = m._secondary_exposures
            end if
            return payload
        end function

        "setSecondaryExposures": function(exposures as object) as void
            m._secondary_exposures = exposures
        end function

        _name: name
        _time: CreateObject("roDateTime").asSeconds() * 1000
        _value: invalid
        _metadata: invalid
        _user: invalid
        _secondary_exposures: invalid
    }
end function

function _hashName(name as String) as String
    ba1 = CreateObject("roByteArray")
    ba1.FromAsciiString(name)
    digest = CreateObject("roEVPDigest")
    digest.Setup("sha256")
    digest.Update(ba1)
    hash = digest.Final()

    ' base64 encode the hash
    ba2 = CreateObject("roByteArray") 
    ba2.FromHexString(hash)
    return ba2.ToBase64String()
end function

function StatsigStore(logger as Object) as object
    this = {
        "checkGate": function(gateName as string) as boolean
            gateHash = _hashName(gateName)
            gate = m._values.feature_gates.Lookup(gateHash)
            
            if (gate = invalid) then
                gate = {value: false, rule_id: "", secondary_exposures: []}
            endif

            m._logger.logGateExposure(gateName, gate.value, gate["rule_id"], gate["secondary_exposures"])
            return gate.value
        end function

        "getConfig": function(configName as string) as object
            configHash = _hashName(configName)
            config = m._values.dynamic_configs.Lookup(configHash)
            if (config <> invalid) then
                dc = DynamicConfig(configName, config.value, config["rule_id"])
                dc._secondaryExposures = config.secondary_exposures
            else
                dc = DynamicConfig(configName, {}, "")
            endif

            m._logger.logConfigExposure(configName, dc._ruleID, dc._secondaryExposures)
            return dc
        end function

        clear: function() as void
            m._values = {
                feature_gates: {}
                dynamic_configs: {}
            }
        end function

        save: function(data as object) as void
            if data = invalid
                return
            else 
                m._values = data
            end if
        end function

        _values: {
            feature_gates: {}
            dynamic_configs: {}
        }

        _logger: logger
    }

    return this
end function

function StatsigLogger(task) as object
    this = {
        "setUser": function(user as object) as void
            m._user = user.toLogDictionary()
        end function

        "log": function(event as object) as void
            m._task.event = {name: "log_event", payload: event.toJson()}
            return
        end function

        "logGateExposure": function(gate as string, value as boolean, ruleID as string, secondary as object) as void
            gateExposure = LogEvent("statsig::gate_exposure")
            gateExposure.setUser(m._user)
            strValue = "false"
            if value
                strValue = "true"
            end if
            gateExposure.setMetadata({
                gate: gate
                "gateValue": strValue
                "ruleID": ruleID
            })
            gateExposure.setSecondaryExposures(secondary)
            
            m.log(gateExposure)
        end function

        "logConfigExposure": function(config as string, ruleID as string, secondary as object) as void
            configExposure = LogEvent("statsig::config_exposure")
            configExposure.setUser(m._user)
            configExposure.setMetadata({
                config: config
                "ruleID": ruleID
            })
            configExposure.setSecondaryExposures(secondary)
            
            m.log(configExposure)
        end function

        "flush": function() as void
            if m._task <> invalid then
                m._task.event = {name: "flush"}
                return
            end if
        end function

        _user: invalid
        _task: task
    }
    return this
end function

function _Statsig_updateUser(user as Object) as void
    if (m._sdk_key = invalid) then
        return
    end if
    m._user = user
    m._logger.setUser(user)
    m._store.clear()
    initializeResult = m._network.initialize(user)
    m._store.save(initializeResult)
end function

function StatsigClient(task, user) as object
    this = {
        "checkGate": function(gateName as String) as boolean
            if (m._store = invalid) then
                return false
            end if
            res = m._store.checkGate(gateName)
            return res
        end function

        "getConfig": function(configName as String) as object
            if (m._store = invalid) then
                return DynamicConfig(configName, {}, "")
            end if
            return m._store.getConfig(configName)
        end function

        "getExperiment": function(experiment as String) as object
            if (m._store = invalid) then
                return DynamicConfig(experiment, {}, "")
            end if
            return m._store.getConfig(experiment)
        end function

        "logEvent": function(eventName as String, value as Dynamic, metadata as object) as void
            if (m._logger = invalid) then
                return
            end if
            
            event = LogEvent(eventName)
            event.setValue(value)
            event.setMetadata(metadata)
            event.setUser(m._user)
        
            m._logger.log(event)
        end function

        "flush": function() as void
            m._logger.flush()
        end function

        "updateUser": function(user) as void
            m._user = user
            ' the pending logs are flushed in StatsigTask
            m._logger.setUser(user)
            m._store.clear()
        end function

        "loadValues": function(user as Object, initializeResult) as void
            if m._logger = invalid
                m._logger = StatsigLogger(m._task)
                m._logger.setUser(user)
                m._store = StatsigStore(m._logger)
            end if
            m._store.save(initializeResult)
        end function

        _user: user
        _logger: invalid
        _store: invalid
        _sdk_key: invalid
        _task: task
    }
    return this
end function