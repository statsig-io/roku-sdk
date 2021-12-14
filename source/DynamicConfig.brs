function DynamicConfig(name as String, value as object, ruleID as string) as object
    if (value = invalid) then
        value = {}
    end if
    
    return {
        "getValue": function() as object
            return m._value
        end function

        "get": function(key as string, defaultValue as dynamic) as dynamic
            if (key = invalid) then
                return defaultValue
            endif
            res = m._value.Lookup(key)
            if (res <> unknown) then
                return res
            else
                return defaultValue
            end if
        end function

        _name: name
        _value: value
        _ruleID: ruleID
        _secondaryExposures: []
    }
end function