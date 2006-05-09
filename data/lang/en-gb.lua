-- en-gb language for colloquy (Default)

lang["en-gb"] = {
  
  NAME = "en-gb",
  PARENT = nil,

  -- Global stuff
  Persons = function(n)
               if( strsub(n, -1, -1) == "s" ) then
                 return n .. "'"
               else
                 return n .. "'s"
               end
            end,

  Plural = function(singular, plural, n)
               if( tonumber(n) ~= 1 ) then
                 return plural
               end
               return singular
          end,

  PublicGroup = "Public",
  BotGroup = "Bots-R-Us",
  DefaultTalkerName = "the talker",
  Usage = "Usage:",
  UnknownUser = "Unknown user '$0'.",
  UnknownGroup = "Unknown group '$0'.",
  UnknownList = "Unknown list '$0'.",
  Ambiguous = "$0 is ambiguous - matches $1.",
  On = "on",
  Off = "off",
  NoPriv = "You don't have sufficent privilege to do that.",
  NotAvailable = "Command not available.",
  Immune = "$0 has immunity.",
  Done = "Done.",
  User = "User",
  Group = "Group",
  List = "List",

  -- commandQuit
  cquitBye = "Bye!",

  -- commandShout
  cshoutUsage = "${Usage} .Shout [;|:]<text>",
  cshoutGagged = "You have been banned from shouting.",

  -- commandLook
  clookActive = "Active users in group $0:",
  clookIdle = "Idle users in group $0:",

  -- commandEmote
  cemoteUsage = "${Usage} .Emote <emotion>",

  -- commandPEmote
  cpemoteUsage = "${Usage} .PEmote <emotion>",

  -- commandHelp
  chelpGeneral = "general",
  chelpCommands = "commands",
  chelpAvailable = "Available commands:",
  chelpNoHelp = "No help found.",

  -- commandGroup
  cgroupBot = "Bots cannot leave ${BotGroup}.",
  cgroupAlready = "You are already in group $0.",
  cgroupLocked = "That group is locked.",
  cgroupInvalid = "Invalid group name.",
  cgroupHasMoved = "$0 has moved to group $1.",
  cgroupEnters = "$0 enters this group.",
  cgroupYouEnter = "You enter group $0.",

  -- commandSpy
  cspyAlready = "${cgroupAlready,$0}",
  cspyInvalid = "${cgroupInvalid}",
  cspyHasMoved = "${cgroupHasMoved,$0,$1}",
  cspyEnters = "${cgroupEnters,$0}",
  cspyYouEnter = "You spy on group $0.",

  -- commandInspect
  cinspectNoUser = "${UnknownUser,$0}",
  cinspectStart = "Started to inspect $0.",
  cinspectStop = "Stopped inspecting $0.",
  cinspectCurrent = "Currently inspecting: $0",
  cinspectSend = "$0 sends: $1",
  cinspectReceive = "$0 recvs: $1",

  -- commandJoin
  cjoinUsage = "${Usage} .Join <${User}>",
  cjoinNoUser = "${UnknownUser,$0}",

  -- commandGroups
  cgroupCurrent = "Current groups are:",

  -- commandGName
  cgnameUsage = "${Usage} .GName <new group name>",
  cgnameBot = "Bots cannot leave ${BotGroup}.",
  cgnamePublic = "You cannot rename ${PublicGroup}.",
  cgnameInvalid = "Invalid group name.",
  cgnameAlready = "Group name is already in use.",
  cgnameMerge = "$0 has merged group $1 into $2.",
  cgnameChange = "$0 has changed the group's name to $1.",

  -- commandInfo
  cinfoAvailable = "Information is available on the following users:",
  cinfoNoUser = "${UnknownUser,$0}",
  cinfoUser = "User",
  cinfoRealName = "Real Name",
  cinfoBanned = "Banned",
  cinfoAliases = "Aliases",
  cinfoAuthenticator = "Authenticator",
  cinfoPrivs = "Privs",
  cinfoSex = "Sex",
  cinfoBirthday = "Birthday",
  cinfoAge = "Age",
  cinfoEmail = "Email",
  cinfoHomepage = "Homepage",
  cinfoOccupation = "Occupation",
  cinfoLocation = "Location",
  cinfoInterests = "Interests",
  cinfoComments = "Comments",
  cinfoNextAround = "Next Around",
  cinfoOnLists = "On Lists",
  cinfoCreated = "Created",
  cinfoLastSite = "Last Site",
  cinfoLastLogon = "Last Logon",
  cinfoLastQuit = "Last Quit",
  cinfoQuitMsg = "Quit Message",
  cinfoTalkBytes = "Talk Bytes",
  cinfoTimeOn = "Time On",
  

  -- commandStats
  cstatsTalkerName = "Talker Name",
  cstatsVersion = "Version",
  cstatsCompiled = "Compiled",
  cstatsStarted = "Started",
  cstatsUpFor = "Up for",
  cstatsDaytime = "Daytime",
  cstatsMaxDayUsers = "Max daytime users",
  cstatsMaxNightUsers = "Max nighttime users",
  cstatsMaxIdle = "Max idle",
  cstatsMaxGuests = "Max guests",
  cstatsGuestTimeout = "Guest time out",
  cstatsGuestTimeoutV = "$0 seconds.",
  cstatsSecsDay = " secs/day, ",
  cstatsResUsage = "Resource usage",
  cstatsDataSent = "Data sent",
  cstatsDataRead = "Data read",
  cstatsBandwidth = "Bandwidth",
  cstatsNone = "None.",
  cstatsMinutes = "$0 minutes.",
  cstatsSeconds = "$0 seconds.",
  cstatsUsage1 = "$0 seconds, $1 kB.",
  cstatsUsage2 = "$0 secs/day, $1 kB.",
  cstatsAverageAge = "Average age of users",
  cstatsAges = "$0 for all, $1 for connected.",
  cstatsCacheStats = "Token cache",
  cstatsUsed = "entries used",
  cstatsHits = "hits",
  cstatsRemoved = "last removed",


  -- commandSet
  csetOn = "On",
  csetOff = "Off",
  csetOptTermDumb = "Dumb",
  csetOptTermColour = "Colour",
  csetOptTermClient = "Client",
  csetOptions = "Options: ",
  csetOptBeep = "Beep $0, ",
  csetOptCR = "CR $0, ",
  csetOptEcho = "Echo $0, ",
  csetOptStrip = "Strip $0, ",
  csetOptPrompts = "Prompts $0, ",
  csetOptShouts = "Shouts $0, ",
  csetOptMessages = "Messages $0, ",
  csetOptLists = "Lists $0, ",
  csetOptIdling = "Idling messages $0, ",
  csetOptIdlePrompt = "Idle Prompt '$0', ",
  csetOptTerminal = "Terminal $0, ",
  csetOptWidth = "Width $0, ",
  csetOptWidthAuto = "Auto ($0 chars)",
  csetOptWidthZero = "0 (no wrapping)",
  csetOptWidthOther = "$0 chars",
  csetOptLanguage = "Language $0.",
  csetUnknown = "Unknown .Set command '$0'.",

  -- commandSet Language
  csetlanguageUsage = "${Usage} .Set Language <language>",
  csetlanguageAvailable = "Available languages: $0",
  csetlanguageUnknown = "Unknown language '$0'.",
  csetlanguageChanged = "Language changed to '${NAME}'.",

  -- commandSet Strip
  csetstripUsage = "${Usage} .Set Strip <${On}|${Off}>",
  csetstripOn = "Strip on.",
  csetstripOff = "Strip off.",

  -- commandSet Echo
  csetechoUsage = "${Usage} .Set Echo <${On}|${Off}>",
  csetechoOn = "Echo on.",
  csetechoOff = "Echo off.",

  -- commandSet Width
  csetwidthAuto = "auto",
  csetwidthUsage = "${Usage} .Set Width <terminal width|${csetwidthAuto}>",
  csetwidthDoneAuto = "Width set to auto.",
  csetwidthNoColour = "Automatic terminal width only works with colour terminals.",
  csetwidthTooSmall = "You can't set a width of less than 79 characters.",
  csetwidthDoneNone = "Width set to 0 (no wrapping).",
  csetwidthDone = "Width set to $0 characters.",

  -- commandSet Prompts
  csetpromptsUsage = "${Usage} .Set Prompts <${On}|${Off}>",
  csetpromptsOn = "Prompts on.",
  csetpromptsOff = "Prompts off.",

  -- commandSet IdlePrompt
  csetidlepromptUsage = "${Usage} .Set IdlePrompt <New Prompt | ->",
  csetidlepromptSet = "Set '$0' as idle prompt.",
  csetidlepromptUnset = "Removed idle prompt.",
  csetidlepromptTooLong = "'$0' is longer than 10 characters.",

  -- commandSet Privs
  csetprivsUsage = "${Usage} .Set Privs <User> <New Privs>",
  csetprivsChanged = "${Persons,$0} privs changed to '$1'.",
  
  -- commandSet TimeWarn
  csettimeUsage = "${Usage} .Set TimeWarn <Minutes>",
  csettimeDone = "Time warning enabled for every $0 minutes.",
  csettimeNone = "Time warning disabled.",

  -- commandSet CR
  csetcrUsage = "${Usage} .Set CR <${On}|${Off}>",
  csetcrOn = "CR on.",
  csetcrOff = "CR off.",

  -- commandSet Term

  csettermUsage = "${Usage} .Set Term <${csetOptTermDumb}|${csetOptTermColour}|${csetOptTermClient}>",
  csettermDone = "Terminal set to '$0'.",
  csettermUnknown = "Unknown terminal type '$0'.",

  -- commandSet Beep
  csetbeepUsage = "${Usage} .Set Beep <${On}|${Off}>",
  csetbeepOn = "Beep on.",
  csetbeepOff = "Beep off.",

  -- commandSet Info
  csetinfoUsage = "${Usage} .Set Info <Field> <Value>",
  csetinfoGuest = "Guest users do not have any information to set.",
  csetinfoFlocation = "location",
  csetinfoFoccupation = "occupation",
  csetinfoFinterests = "interests",
  csetinfoFcomments = "comments",
  csetinfoFaround = "around",
  csetinfoFemail = "email",
  csetinfoFhomepage = "homepage",
  csetinfoInvalid = "Unknown field '$0'.",
  csetinfoChanged = "Field '$0' changed to '$1'.",
  csetinfoUnset = "Field '$0' unset.",

  -- commandSet Heard
  csetheardShouts = "shouts",
  csetheardMessages = "messages",
  csetheardLists = "lists",
  csetheardIdling = "idling",
  csetheardShoutsOn = "Shouts are heard.",
  csetheardShoutsOff = "Shouts are not heard.",
  csetheardMessagesOn = "Connection messages are heard.",
  csetheardMessagesOff = "Connection messages are not heard.",
  csetheardListsOn = "Lists are heard.",
  csetheardListsOff = "Lists are not heard.",
  csetheardIdlingOn = "Idling messages are heard.",
  csetheardIdlingOff = "Idling messages are not heard.",

  -- commandClosedown
  cclosedownBroadcast = "Talker closed down by $0.",
  cclosedownReason = "- Closedown",

  -- commandForce
  cforceUsage = "${Usage} .Force <User> <Command>",
  cforceDone = "Forced '$0' to do '$1'.",

  -- commandHelpUser
  chelpuserUsage = "${Usage} .HelpUser <User> <Help Topic>",
  chelpuserDone = "Shown '$0' help topic '$1'.",

  -- commandSaveData
  csavedataDone = "User data saved to '$0'.",

  -- commandPassword
  cpasswordUsage = "${Usage} .Password <Old> <New>",
  cpasswordGuest = "You do not have a password to change.",
  cpasswordDone = "Password changed.",
  cpasswordFail = "Failure changing password.",

  -- commandLua
  cluaDone = "Executed '$0'.",

  -- commandNewUser
  cnewuserUsage = "${Usage} .NewUser <Username> <Password>",
  cnewuserAlready = "A user with the name '$0' already exists.",
  cnewuserDone = "User '$0' created.",

  -- commandDeleteUser
  cdeleteuserUsage = "${Usage} .DeleteUser <Username>",
  cdeleteuserDone = "Deleted user '$0'.",

  -- commandTell
  ctellUsage = "${Usage} .Tell {<${User}>|@[${Group}>]}[,[-]{<${User}>|@<${Group}>}[,...]] <Message>",
  ctellNone = "No whispers heard yet.",
  ctellToGroup = "Whispered to group $0: '$1'",
  ctellDone = "Whispered to $0: '$1'",
  ctellMultipleGroup = "The group '$0' is in the list more than once.",
  ctellMultipleUser = "The user '$0' (or an alias) is in the list more than once.",
  ctellNoUser = "'$0' is not logged on, and matches no aliases.",
  ctellNoRemove = "'$0' cannot be removed from the send list, as they are not in it.",

  -- commandRemote
  cremoteUsage = "${Usage} .REmote {<${User}>|@[${Group}>]}[,[-]{<${User}>|@<${Group}>}[,...]] <Emotion>",
  cremoteNone = "${ctellNone}",
  cremoteToGroup = "REmote'd to group $0: '$1'",
  cremoteDone = "REmote'd to $0: '$1'",
  cremoteMultipleGroup = "${ctellMultipleGroup,$0}",
  cremoteNoUser = "${ctellNoUser,$0}",
  cremoteNoRemove = "${ctellNoRemove,$0}",
  
  -- commandUserInfo
  cuserinfoUsage = "${Usage} .UserInfo <User> <Field> <Value>",
  cuserinfoAlready = "${cnewuserAlready,$0}",
  cuserinfoDone = "User's '$0' field changed to '$1'.",
  cuserinfoCataliases = "aliases",
  cuserinfoCatusername = "username",
  cuserinfoCatpassword = "password",
  cuserinfoCatname = "name",
  cuserinfoCatbirthday = "birthday",
  cuserinfoCatlocation = "location",
  cuserinfoCatoccupation = "occupation",
  cuserinfoCatinterests = "interests",
  cuserinfoCatcomments = "comments",
  cuserinfoCataround = "around",
  cuserinfoCathomepage = "homepage",
  cuserinfoCatemail = "email",
  cuserinfoCatsex = "sex",
  cuserinfoCatprivs = "privs",
  cuserinfoCatauth = "authenticator",
  cuserinfoCatquitmsg = "quitmsg",
  cuserinfoCatunknown = "Unknown field '$0'.",
  cuserinfoUnset = "<unset>",
  

  -- commandExamine
  cexamineUsage = "${Usage} .Examine <User>",
  cexamineFUser = "User",
  cexamineFName = "Name",
  cexamineFStatus = "Status",
  cexamineFRestrictions = "Restrictions",
  cexamineFGroup = "Group",
  cexamineFInvitations = "Invitations",
  cexamineFPausedLists = "Paused Lists",
  cexamineFSite = "Site",
  cexamineFVia = "Via",
  cexamineFOnSince = "On Since",
  cexamineFOnFor = "On For",
  cexamineFTalkBytes = "Talk Bytes",
  cexamineFIdleFor = "Idle For",
  cexamineFIdle = "Idle",
  cexamineFTotalIdle = "Total Idle",

  cexamineOnAs = " (logged on as $0)",
  cexamineMaster = "Master ($0)",
  cexaminePrived = "Privileged User ($0)",
  cexamineNormal = "Normal User",
  cexamineGuest = "Guest",
  cexamineGagged = "Gagged ",
  cexamineCensored = "Censored ",
  cexamineBot = "Bot ",

  -- commandIdle
  cidleIdle = "$0 starts idling. $1",
  cidleReidle = "$0 reidles. $1",
  cidleYouIdle = "You start idling. $0",
  cidleYouReidle = "You reidle. $0", 

  -- commandName
  cnameUsage = "${Usage} .Name <User> <New Name>",
  cnameInvalid = "Invalid new name.",
  cnameAlready = "New name is already in use.",
  cnameMyNameDone = "$0 has changed name to $1.",
  cnameDone = "$0 has changed ${Persons,$1} name to $2.",
  
  -- commandNameSelf
  cnameselfGuest = "Only registered users are allowed to use .NameSelf",
  cnameselfAlreadyNamed = "You are already named '$0'.  No change made.",
  cnameselfAlready = "Name already in use.",
  cnameselfChanged = "Changed your name to '$0'.",
  cnameselfNotSame = "'$0' is not the same user name as '$1'.",
  cnameselfAllChange = "${cnameMyNameDone,$0,$1}",

  -- commandWarn
  cwarnUsage = "${Usage} .Warn <User> <Reason>",
  cwarnDone = "$0 warns $1 ($2)",

  -- commandKick
  ckickUsage = "${Usage} .Kick <User> [<Reason>]",
  ckickMessage = "You have been kicked off.  $0",
  ckickDefault = "Come back when you are more sensible.",

  -- commandInvis
  cinvisDone = "You become invisible.",

  -- commandVis
  cvisDone = "You become visible.",

  -- commandRequest
  crequestUsage = "${Usage} .Request <text>",
  crequestError = "Unable to send request: $0",
  crequestDone = "Request received.",

  -- commandTime
  ctimeDone = "Current local time: $0",

  -- commandWho
  cwhoGroup = "Users in group $0 at the moment:",
  cwhoAll = "Users on $0 at the moment:",
  cwhoColumns = "Name         Group               Flags  Idle  Site",
  cwhoIdle = "IDLE",
  cwhoTotal = "$1 active ${Plural,user,users,$1} ($2 idle), $0 total.",

  -- commandLWho
  clwhoUsage = "${Usage} .LWho <List Name>",
  clwhoList = "Users on list '$0' connected at the moment:",
  clwhoColumns = "${cwhoColumns}",
  clwhoIDLE = "${cwhoIdle}",
  clwhoTotal = "$1 active ${Plural,user,users,$1} ($2 idle), $0 total.",

  -- commandGag
  cgagUsage = "${Usage} .Gag <User>",
  cgagAlready = "$0 is already gagged.",
  cgagGag = "$0 has been gagged by $1.",

  -- commandCensor
  ccensorUsage = "${Usage} .Censor <User>",
  ccensorAlready = "$0 is already censored.",
  ccensorCensor = "$0 has been censored by $1.",

  -- commandUngag
  cungagUsage = "${Usage} .UnGag <User>",
  cungagAlready = "$0 is not gagged.",
  cungagSelf = "You cannot ungag yourself.",
  cungagUngag = "$0 has been ungagged by $1.",

  -- commandUnCensor
  cuncensorUsage = "${Usage} .UnCensor <User>",
  cuncensorAlready = "$0 is not censored.",
  cuncensorSelf = "You cannot uncensor yourself.",
  cuncensorUncensor = "$0 has been uncensored by $1.",

  -- commandBanUser
  cbanuserUsage = "${Usage} .BanUser <User> <Reason>",
  cbanuserDone = "Banned $0.",

  -- commandUnBanUSer
  cunbanuserUsage = "${Usage} .UnBanUser <User>",
  cunbanuserAlready = "$0 is not banned.",
  cunbanuserDone = "Unbanned $0.",

  -- commandLockTalker
  clocktalkerDone = "$0 has locked the talker.",

  -- commandUnlockTalker
  cunlocktalkerDone = "$0 has unlocked the talker.",

  -- commandAlert
  calertUsage = "${Usage} .Alert <Message>",
  calertDone = "URGENT MESSAGE: $0",

  -- commandLogin
  cloginUsage = "${Usage} .Login <Username> <Password>",
  cloginAlready = "Username '$0' is already in use.",
  cloginPassword = "Incorrect password.",
  cloginBanned = "$0 has been banned: $1",
  cloginNoNormal = "$0 has not logged in normally yet.",
  cloginDone = "$0 has logged on as, and changed name to $1.",
  cloginFailures = "$0 failed ${Plural,login,logins,$0} since your last connection.",

  -- commandComment
  ccommentNone = "You don't have a comment to remove.",
  ccommentRemove = "Comment removed.",
  ccommentSet = "Comment set to '$0'.",

  -- commandComments
  ccommentsNone = "No comments set.",

  -- commandWake
  cwakeUsage = "${Usage} .Wake <User>",
  cwakeAttempts = "$0 attempts to wake you.",
  cwakeDone = "Attempted to wake $0.",

  -- commandLock
  clockPublic = "You cannot lock ${PublicGroup}.",
  clockAlready = "The group is already locked.",
  clockDone = "$0 has locked the group.",

  -- commandUnlock
  cunlockPublic = "You cannot unlock Public.",
  cunlockAlready = "The group is not locked.",
  cunlockDone = "$0 has unlocked the group.",

  -- commandInvite
  cinviteUsage = "${Usage} .Invite <Users>",
  cinviteAlready = "$0 is already in this group.",
  cinviteDone = "$0 has invited $1.",
  cinviteUser = "$0 has invited you to group $1.  To respond, type .join $2",
  
  -- commandIdlers
  cidlersGroup = "Idlers in group '$0' at the moment:",
  cidlersAll = "Idlers on $0 at the moment:",
  cidlersHeader = "Name       Time     Reason",
  cidlersTotal = "$0 total.",

  -- commandEvict
  cevictUsage = "${Usage} .Evict <User>",
  cevictSelf = "You cannot evict yourself.",
  cevictPublic = "You cannot evict somebody from ${PublicGroup}.",
  cevictEvictee = "You have been evicted by $0.",
  cevictOthers = "$0 has been evicted here by $1.",
  cevictDone = "$0 has evicted $1.",
  cevictGroup = "You cannot evict somebody from a group you are not in.",

  -- commandQuery
  cqueryNone = "Not in query mode.",
  cqueryEnd = "Query mode ended.",
  cqueryNoList = "You are not a member of that list, and it is not open.",
  cqueryList = "Query mode selected for list '$0'.",
  cqueryGroup = "Query mode selected for group '$0'.",
  cqueryUser = "Query mode selected for user '$0'.",

  -- commandBan
  cbanUsage = "${Usage} .Ban [<Host> <Reason>]",
  cbanDone = "'$0' added to the banned hosts list.",
  cbanHeader = "The following hosts are banned:",

  -- commandUnban
  cunbanUsage = "${Usage} .UnBan <Host>",
  cunbanNone = "'$0' is not in the banned hosts list.",
  cunbanDone = "'$0' removed from the banned hosts list.",

  -- commandIgnore
  cignoreIgnoring = "You are currently ignoring:",
  cignoreIgnored = "You are currently being ignored by:",
  cignoreNobody = " Nobody",
  cignoreSelf = "You cannot ignore yourself.",
  cignoreAlready = "You are already ignoring %s.  Use .UnIgnore to stop ignoring them.",
  cignoreSilently = "silently",
  cignoreDone = "Ignoring '$0'.",
  cignoreIgnoree = "$0 ignores you$1.",

  -- commandUnignore
  cunignoreUsage = "${Usage} .UnIgnore <User>",
  cunignoreAlready = "You are not ignoring '$0'.",
  cunignoreDone = "Stopped ignoring '$0'.",
  cunignoreIgnoree = "$0 stops ignoring you$1.",

  -- commandWhoAmI
  cwhoamiNormal = "You are logged on as '$0'.",
  cwhoamiOther = "You are logged on as '$0', named '$1'.",

  -- commandBot
  cbotUsage = "${Usage} .Bot <User>",
  cbotNot = "'$0' does not end in 'Bot'",
  cbotAlready = "'$0' is already flagged as a bot.",
  cbotDone = "$0 has been made a bot by $1.",

  -- commandUnBot
  cunbotUsage = "${Usage} .UnBot <User>",
  cunbotAlready = "'$0' is not flagged as a bot.",
  cunbotDone = "$0 has been unflagged as a bot by $1.",

  -- commandBots
  cbotsName = "Name",
  cbotsUse = "Use",
  cbotsUseless = "Useless",
  cbotsTotal = "$0 total.",
  cbotsNone = "No bots are currently connected.",
  
  -- commandLastOn
  clastonUsage = "${Usage} .LastOn <User|%List>",
  clastonHeader = "User         Last on",
  clastonConnected = "Connected in group '$0', idle $1.",
  clastonNoExist = "Does not exist.",
  clastonNever = "Never connected.",
  clastonTotal = "$0 total.",
  clastonUser = "$0 is connected in group '$1', idle $2.",
  clastonUserNever = "$0 has never connected.",
  clastonUserConn = "$0 was connected $1.",

  -- commandGuest
  cguestUsage = "${Usage} .Guest <User>",
  cguestAlready = "$0 is not a guest.",
  cguestNoGuest = "The 'guest' user does not exist.  You must creat it with .newuser",
  cguestDone = "$0 has been logged on as a guest by $1.",


  cobserveNone = "You are not observing any groups.",
  cobserveList = "You are currently observing: $0",
  cobserveAlready = "You are already observing group '$0'.",
  cobserveDone = "$0 observes this group.",
  cobserveStart = "You start observing '$0'.",

  cdisregardUsage = "${Usage} .Disrecard <Group>",
  cdisregardAlredy = "You are not currently observing group '$0'.",
  cdisregardDone = "$0 disregards this group.",
  cdisregardFinished = "You disregard '$0'.",

  cswapUsage = "${Usage} .Swap <User> <Password>",
  cswapNoUser = "${UnknownUser,$0}",
  cswapNoPassword = "That user doesn't have a password.",
  cswapSwapped = "Swapped connections with $0.",

  -- Connection/disconnection stuff

  gConnectGuest = " (guest)",
  gConnectBirthday = " - BIRTHDAY!",
  gConnectGroup = "$0$1 has connected from $2 in group $3$4",
  gConnect = "$0$1 has connected from $2$3",
  gInvisConnect = "$0 has (invisibly) connected from $1 in group $2$3",
  gDisconnect = "$0 has disconnected! $1",
  gInvisDisconnect = "$0 has (invisibly) disconnected! $1",
  gConnecting = "User connecting from $0.",

  gGuestTimeout = "Your guest login has timed out.",
  gGuestTimeout1 = "Your guest login will time out in 1 minute.",
  gIdledOut = "You have idled out.",
  gAutoIdle = "$0 starts automatically idling.",
}
