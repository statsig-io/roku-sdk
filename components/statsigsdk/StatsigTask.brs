sub init()
    m.top.functionName = "initializeImpl"
end sub
  
sub initializeImpl()
    m.port = createObject("roMessagePort")
    m.top.observeField("event", m.port)
    
    m.taskCheckInterval = 250

    m._logs = []

    user = StatsigUser()
    user.fromEvaluationDictionary(m.top.userAttributes)
    m._network = StatsigNetwork(m.top.sdkKey, user)
    values = m._network.initialize()
    m.top.initializeValues = values

    startEventLoop()
    shutdown()
end sub
  
sub startEventLoop()
    if m.top.event <> invalid then
        handleEvent(m.top.event)
    end if

    cnt = 0
    while (true)
        message = wait(m.taskCheckInterval, m.port)
        cnt = cnt + 1
        if message = invalid then
            'noop for now
        else
            messageType = type(message)
            if messageType = "roSGNodeEvent" then
                field = message.getField()
                if field = "event" then
                    handleEvent(message.getData())
                end if
            end if
        end if
        if cnt >= 40 then
            flushLogs()
            cnt = 0
        end if
    end while
end sub
  
sub shutdown()
    flushLogs()
end sub

sub flushLogs()
    if m._logs.Count() = 0
        return
    end if
    m._network.postLogs(m._logs)
    m._logs = []
end sub

sub updateUser()
    flushLogs()
    user = StatsigUser()
    user.fromEvaluationDictionary(m.top.userAttributes)
    m._network.setUser(user)
    m.top.initializeValues = m._network.initialize()
end sub
  
sub handleEvent(data)
    event = data.name
    if event = invalid then
        return
    else if event = "log_event"
        m._logs.push(data.payload)
    else if event = "flush"
        flushLogs()
    else if event = "update_user"
        updateUser()
    else
        return
    end if
end sub

function getTransport(sdkKey as string, url as string, port as object) as object
    transport = createObject("roUrlTransfer")
    transport.addHeader("Content-Type", "application/json")
    transport.addHeader("Accept", "application/json")
    transport.setCertificatesFile("common:/certs/ca-bundle.crt")
    
    transport.SetPort(port)
    transport.InitClientCertificates()
    transport.addHeader("STATSIG-API-KEY", sdkKey)
    transport.SetUrl(url)
    return transport
end function

function StatsigNetwork(sdkKey, user) as object
    port = createObject("roMessagePort")
    transport = getTransport(sdkKey, "https://api.statsig.com/v1/initialize", port)
    
    logTransport = getTransport(sdkKey, "https://api.statsig.com/v1/log_event", createObject("roMessagePort"))

    deviceInfo = CreateObject("roDeviceInfo")
    storage = {}
    storage.section = CreateObject("roRegistrySection", "STATSIG_SDK")
    stableID = storage.section.Read("STABLE_ID")
    if stableID = invalid or stableID = "" then
        stableID = deviceInfo.GetRandomUUID()
        storage.section.Write("STABLE_ID", stableID)
        storage.section.Flush()
    end if

    return {
        "setUser": function(user) as object
            m._user = user
        end function

        "initialize": function() as object
            if m._transport.asyncPostFromString(formatJSON({
                "statsigMetadata": m._sdk_metadata,
                user: m._user.toEvaluationDictionary()
            })) then
                msg = Wait(3000, m._port)
                values = parseJSON(msg)
                if values["feature_gates"] <> invalid and values["dynamic_configs"] <> invalid then
                    return values
                else
                    return {feature_gates: {}, dynamic_configs: {}}
                end if
            end if
        end function

        "postLogs": function(events as object) as dynamic
            payload = formatJSON({
                "statsigMetadata": m._sdk_metadata,
                events: events
            })
            m._logTransport.asyncPostFromString(payload)
        end function

        _transport: transport
        _logTransport: logTransport
        _port: port
        
        _user: user
        _sdkKey: sdkKey
        _sdk_metadata: {
            "sdkVersion": "0.1.0",
            "sdkType": "roku-client",
            "sessionID": deviceInfo.GetRandomUUID(),
            "stableID": stableID,
        }
    }
end function