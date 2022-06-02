class IC_ServerCalls_Class
{
    __New()
    {
        idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        if !isObject(idle) 
        {
            msgbox failed to open a handle
            if (hProcessCopy = 0)
                msgbox Idle Champions isn't running (not found) or you passed an incorrect program identifier parameter. In some cases _ClassMemory.setSeDebugPrivilege() may be required. 
            else if (hProcessCopy = "")
                msgbox OpenProcess failed. If Idle Champions has admin rights, then the script also needs to be ran as admin. _ClassMemory.setSeDebugPrivilege() may also be required. Consult A_LastError for more information.
            ExitApp
        }
        WRLpath := idle.GetModuleFileNameEx()
        foundPos := InStr(WRLpath, "IdleDragons.exe")
        this.WRLpath := SubStr(WRLpath, 1, foundPos - 1) . "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
        idle := ""
        this.userID := this.GetDataFromWRL("""internal_user_id"":""", """")
        this.userHash := this.GetDataFromWRL("""hash"":""", """")
        this.networkID := this.GetDataFromWRL("network_id=", "&")
        this.clientVersion := this.GetDataFromWRL("mobile_client_version=", "&")
        this.dummyData := "&language_id=1&timestamp=0&request_id=0&network_id=" . this.networkID . "&mobile_client_version=" . this.clientVersion
        this.gameInstanceID := this.GetDataFromWRL("""game_instance_id"":""", """")
        this.shinies := 0
        return this
    }

    GetVersion()
    {
        return "IC_ServerCalls_Class: v3.0.0, 04/17/2022"
    }

    ;============================================================
    ;Various server call functions that should be pretty obvious.
    ;============================================================
    ;Except this one, it is used internally and shouldn't be called directly.
    ServerCall( callName, parameters ) 
    {
        response := ""
        URLtoCall := this.webRoot . "post.php?call=" . callName . parameters
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( "10000", "10000", "10000", "10000" )
        Try {
            WR.Open( "POST", URLtoCall, true )
            WR.SetRequestHeader( "Content-Type","application/x-www-form-urlencoded" )
            WR.Send()
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
                ; TODO: Add check for outdated Instance ID
                if(!(response.switch_play_server == ""))
                {
                    return this.ServerCall( callName, parameters ) 
                }
            }
            catch
            {
                this.LogCall(callName, "Failed to fetch valid JSON response from server.")
            }
        }
        if !(response.success)
            this.LogCall(callName, data)
        return response
    }

    LogCall(callName, response)
    {
        if !(this.doLog)
            return
        obj := {}
        obj.callName := callName
        obj.response := response
        string := JSON.stringify(obj)
        FileAppend, % "`n`n" . string, FailedServerCalls.json
    }

    CallUserDetails() 
    {
        getUserParams := this.dummyData . "&include_free_play_objectives=true&instance_key=1&user_id=" . this.userID . "&hash=" . this.userHash
        userDetails := this.ServerCall( "getuserdetails", getUserParams )
        return userDetails
    }

    CallLoadAdventure( adventureToLoad, patronID := 0 ) 
    {
        patronTier := patronID ? 1 : 0
        advParams := this.dummyData . "&patron_tier=" . patronTier . "&user_id=" . this.userID . "&hash=" . this.userHash . "&instance_id=" . this.InstanceID 
            . "&game_instance_id=" . this.gameInstanceID . "&adventure_id=" . adventureToLoad . "&patron_id=" . patronID
        return this.ServerCall( "setcurrentobjective", advParams )
    }

    ;calling this loses everything earned during the adventure, should only be used when stuck.
    CallEndAdventure() 
    {
        advParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.InstanceID "&game_instance_id=" this.gameInstanceID
        return this.ServerCall( "softreset", advParams )
    }

    ;sample: call=convertresetcurrency&language_id=1&user_id=___&hash=___&converted_currency_id=17&target_currency_id=1&timestamp=0&request_id=0&network_id=0&mobile_client_version=999&localization_aware=true&instance_id=___& 
    ; Valid Target Currencies: 1 (Torm), 3 (Kalemvor), 15 (Helm), 22 (Tiamat), 23 (Auril), 25 (Corellon)
    CallConverCurrency(toCurrency := 1, fromCurrency := 24) 
    {
        advParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.InstanceID
        extraParams := "&converted_currency_id=" . fromCurrency . "&target_currency_id=" . toCurrency
        return this.ServerCall( "convertresetcurrency", (advParams . extraParams))
    }

    CallBuyChests( chestID, chests )
    {
        if ( chests > 100 )
            chests := 100
        else if ( chests < 1 )
            return
        if(chestID != 152 AND chestID != 153 AND chestID != 219  AND chestID != 311 )
        {
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.InstanceID "&chest_type_id=" chestID "&count=" chests
            return this.ServerCall( "buysoftcurrencychest", chestParams )
        }
        else
        {
            switch chestID
            {
                case 152:
                    itemID := 1
                    patronID := 1
                case 153:
                    itemID := 23
                    patronID := 2
                case 219:
                    itemID := 45
                    patronID := 3
                case 311:
                    itemID := 76
                    patronID := 4
                Default:
                    return ""
            }
            chestParams := this.dummyData "&user_id=" this.userID "&hash=" this.userHash "&instance_id=" this.InstanceID "&patron_id=" patronID "&shop_item_id=" itemID
            return this.ServerCall( "purchasepatronshopitem", chestParams )
        }
    }

    CallOpenChests( chestID, chests )
    {
        if ( chests > 99 )
            chests := 99
        else if ( chests < 1 )
            return
        chestParams := "&gold_per_second=0&checksum=4c5f019b6fc6eefa4d47d21cfaf1bc68&user_id=" this.userID "&hash=" this.userHash 
            . "&instance_id=" this.InstanceID "&chest_type_id=" chestid "&game_instance_id=" this.gameInstanceID "&count=" chests
        return this.ServerCall( "opengenericchest", chestParams )
    }

    ;A method to check if the party is on the world map. Necessary state to use callLoadAdventure()
    IsOnWorldMap()
    {
        currentAdventure := 0
        userDetails := this.CallUserDetails()
        if ( !IsObject( userDetails ) )
            return "Failed to fetch or build user details."
        for k, v in userDetails.details.game_instances
        {
            if (v.game_instance_id == this.activeInstanceID) 
            {
                currentAdventure := v.current_adventure_id
            }
        }
        if ( currentAdventure == -1 )
            return 1
        else
            return 0
    }

    ParseChestResults( chestResults )
    {
        this.shinies := 0
        string := ""
        for k, v in chestResults.loot_details
        {
            if v.gilded
            {
                this.shinies += 1
                string .= "New shiny! Champ ID: " . v.hero_id . " (Slot " . v.slot_id . ")`n"
            }
        }
        return string
    }

    ServerCallSave( saveBody ) 
    {
        response := ""
        URLtoCall := this.webroot "post.php?call=saveuserdetails&"
        WR := ComObjCreate( "WinHttp.WinHttpRequest.5.1" )
        WR.SetTimeouts( "10000", "10000", "10000", "10000" )
        Try {
            WR.Open( "POST", URLtoCall, true )
            boundaryHeader = 
            (
                multipart/form-data; boundary="BestHTTP"
            )
            WR.SetRequestHeader( "Content-Type", boundaryHeader )
            WR.SetRequestHeader( "User-Agent", "BestHTTP" )
            ;WR.SetRequestHeader( "Accept-Encoding", "identity" )
            WR.Send(saveBody)
            WR.WaitForResponse( -1 )
            data := WR.ResponseText
            Try
            {
                response := JSON.parse(data)
                ; TODO: Add check for outdated Instance ID
                if(!(response.switch_play_server == ""))
                {
                    return this.ServerCallSave( saveBody ) 
                }
            }
            ;catch "Failed to fetch valid JSON response from server."
        }
        return response
    }

    ;looks for the first instance of the string param, which should be the key identifier including quotes, semi colon and begin quote of data value if quoted
    ;then looks for string 2 param, first character after end of data value, usually a " or , or &
    ;trims out the data value
    ;returns the data value
    GetDataFromWRL(string, string2, occurance := 1)
    {
        wrlPath := this.WRLpath
        FileRead, wrl, %wrlPath%
        foundPos := InStr(wrl, string,,, occurance) + StrLen(string)
        endPos := InStr(wrl, string2,, foundPos + 1)
        length := endPos - foundPos
        data := SubStr(wrl, foundPos, length)
        wrl := ""
        return data
    }

    InstanceID[]
    {
        get
        {
            return this.GetDataFromWRL("""instance_id"":", ",")
        }
    }

    webRoot[]
    {
        get
        {
            wrlPath := this.WRLpath
            FileRead, wrl, %wrlPath%
            foundPos := InStr(wrl, "http://ps",,, 3)
            stringEnd := "~idledragons/"
            endPos := InStr(wrl, stringEnd,, foundPos + 1)
            length := endPos - foundPos + StrLen(stringEnd)
            data := SubStr(wrl, foundPos, length)
            wrl := ""
            return data
        }
    }
}