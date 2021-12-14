function StatsigUser() as object
    return {
        "setUserID": function(userID as String) as void
            m._attributes["userID"] = userID
        end function

        "setEmail": function(email as String) as void
            m._attributes["email"] = email
        end function

        "setIP": function(ip as String) as void
            m._attributes["ip"] = ip
        end function

        "setUserAgent": function(userAgent as String) as void
            m._attributes["userAgent"] = userAgent
        end function

        "setCountry": function(country as String) as void
            m._attributes["country"] = country
        end function

        "setLocale": function(locale as String) as void
            m._attributes["locale"] = locale
        end function

        "setAppVersion": function(appVersion as String) as void
            m._attributes["appVersion"] = appVersion
        end function

        "setCustomAttributes": function(custom as object) as void
            m._attributes["custom"] = custom
        end function

        "setPrivateAttributes": function(attrs as object) as void
            m._attributes["privateAttributes"] = attrs
        end function

        "setCustomIDs": function(ids as object) as void
            m._attributes["customIDs"] = ids
        end function

        "toLogDictionary": function() as object
            attrs = {}

            for each key in m._attributes
                'drop private attributes and invalid entries from event logs
                if key <> "privateAttributes" and m._attributes[key] <> invalid then
                    attrs[key] = m._attributes[key]
                end if
            end for
            return attrs
        end function

        "toEvaluationDictionary": function() as object
            return m._attributes
        end function

        "fromEvaluationDictionary": function(attributes) as object
            m._attributes = attributes
        end function

        _attributes: {
            "userID": invalid
            "email": invalid
            "ip": invalid
            "userAgent": invalid
            "country": invalid
            "locale": invalid
            "appVersion": invalid
            "custom": invalid
            "privateAttributes": invalid
            "customIDs": invalid
        }
    }
end function