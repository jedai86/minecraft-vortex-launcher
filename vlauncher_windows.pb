﻿; Prevents multiple instances------------------------------------------------------------

#MyApp="Vortex Minecraft Launcher"
Mutex=CreateMutex_(0,1,#MyApp)
If GetLastError_()=#ERROR_ALREADY_EXISTS
  MessageRequester(#MyApp,"One instance is already started.")
  End
EndIf

EnableExplicit

; Definition of variables------------------------------------------------------------

Define.s workingDirectory = GetPathPart(ProgramFilename())
Global.s tempDirectory = GetTemporaryDirectory()

Global Dim programFilesDir.s(1)
Global.i downloadOkButton
Global.i downloadThread
Global.i downloadThreadsAmount
Global.i asyncDownload
Global.i versionsGadget, playButton, javaListGadget, saveMainButton, exitProgButton
Global.i progressBar, filesLeft, progressWindow, downloadingClientTextGadget
Global.i versionsDownloadGadget, downloadVersionButton
Global.i forceDownloadMissingLibraries
Global.s versionsManifestString

Global Dim javaPaths.s(3)
Global NewMap javaBinMap.i()

Define *FileBuffer
Define.i javaProgram
Define.i Event, font, ramGadget, nameGadget, javaPathGadget, argsGadget, downloadButton, settingsButton, launcherVersionGadget, launcherAuthorGadget
Define.i saveLaunchString, versionsTypeGadget, saveLaunchStringGadget, launchStringFile, inheritsJsonObject, jsonInheritsArgumentsModernMember, allocateAllRam, allocateAllRamGadget, useOptimisedLaunch, useOptimisedLaunchGadget
Define.i argsTextGadget, javaBinaryPathTextGadget, downloadThreadsTextGadget, downloadAllFilesGadget, javaPathGadget
Define.i gadgetsWidth, gadgetsHeight, gadgetsIndent, windowWidth, windowHeight
Define.i listOfFiles, jsonFile, jsonObject, jsonObjectObjects, fileSize, jsonJarMember, jsonArgumentsArray, jsonArrayElement, inheritsJson, clientSize
Define.i releaseTimeMember, releaseTime, jsonJvmArray, loggingMember, loggingClientMember, loggingFileMember, logConfSize

Define.s playerName, ramAmount, clientVersion, javaBinaryPath, fullLaunchString, assetsIndex, clientUrl, fileHash, versionToDownload, gameDir, javaBinaryPathToSave
Define.s assetsIndex, clientMainClass, clientArguments, inheritsClientJar, customLaunchArguments, clientJarFile, nativesPath, librariesString
Define.s uuid, jvmArguments, logConfId, logConfUrl, logConfArgument

Define.i downloadMissingLibraries, jsonArgumentsMember, jsonArgumentsModernMember, jsonInheritsFromMember
Define.i downloadMissingLibrariesGadget, downloadThreadsGadget, asyncDownloadGadget, saveSettingsButton, useCustomJavaGadget, useCustomParamsGadget, keepLauncherOpenGadget, closeSettingsButton
Define.i i
Define.i maxSystemMemory, maxFreeMemory, defaultMemory

; Memory detection
maxSystemMemory = MemoryStatus(#PB_System_TotalPhysical) / 1048576

Select maxSystemMemory
  Case 128 To 1899
    defaultMemory = 512
    maxFreeMemory = 512
  Case 1900 To 2999
    defaultMemory = 1000
    maxFreeMemory = 1024
  Case 3000 To 5899
    defaultMemory = 2048
    maxFreeMemory = 2536
  Case 5900 To 7499
    defaultMemory = 3072
    maxFreeMemory = 4096
  Case 7500 To 9999
    defaultMemory = 6000
    maxFreeMemory = 6144
  Case 10000 To 13999
    defaultMemory = 8000
    maxFreeMemory = 8192
  Case 14000 To 17000
    defaultMemory = 8192
    maxFreeMemory = maxSystemMemory - 2048
  Case 17001 To 512000
    defaultMemory = 10240
    maxFreeMemory = maxSystemMemory - 4096
  Default
    defaultMemory = 512
    maxFreeMemory = 512
EndSelect
    

Define.s playerNameDefault = GetEnvironmentVariable("USERNAME"), ramAmountDefault = Str(defaultMemory)
Define.s customLaunchArgumentsDefault = "-XX:+UnlockExperimentalVMOptions -XX:+ParallelRefProcEnabled -XX:ParallelGCThreads=" + Str(CountCPUs(#PB_System_CPUs)) + " -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M"
Define.s customOldLaunchArgumentsDefault = "-XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -XX:-UseAdaptiveSizePolicy -Xmn128M"
Define.s customOptimizedLaunchArgumentsDefault = "-XX:+UnlockExperimentalVMOptions -XX:ParallelGCThreads=" + Str(CountCPUs(#PB_System_CPUs)) + " -XX:InitiatingHeapOccupancyPercent=10 -XX:AllocatePrefetchStyle=1 -XX:+UseSuperWord -XX:+OptimizeFill -XX:LoopUnrollMin=4 -XX:LoopMaxUnroll=16 -XX:+UseLoopPredicate -XX:+RangeCheckElimination -XX:+CMSCleanOnEnter -XX:+EliminateLocks -XX:+DoEscapeAnalysis -XX:+TieredCompilation -XX:+UseCodeCacheFlushing -XX:+UseFastJNIAccessors -XX:+CMSScavengeBeforeRemark -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses -XX:+ScavengeBeforeFullGC -XX:+AlwaysPreTouch -XX:+UseFastAccessorMethods -XX:G1HeapWastePercent=10 -XX:G1MaxNewSizePercent=10 -XX:G1HeapRegionSize=32M -XX:G1NewSizePercent=10 -XX:MaxGCPauseMillis=200 -XX:+OptimizeStringConcat -XX:+UseParNewGC -XX:+UseNUMA -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:SurvivorRatio=2 -XX:+DisableExplicitGC" 
Define.i downloadThreadsAmountDefault = 10
Define.i asyncDownloadDefault = 1
Define.i downloadMissingLibrariesDefault = 1
Define.i downloadAllFilesDefault = 0
Define.i versionsTypeDefault = 0
Define.i saveLaunchStringDefault = 1
Define.i useCustomParamsDefault = 0
Define.i keepLauncherOpenDefault = 0
Define.i allocateAllRamDefault = 0
Define.i useOptimisedLaunchDefault = 0
Global.i useCustomJavaDefault = 0
Global.s javaBinaryPathDefault = "C:\jre8\bin\javaw.exe"

Define.s launcherVersion = "2.0.5"
Define.s launcherDeveloper = "Kron4ek&Jedai86"


Declare assetsToResources(assetsIndex.s)
Declare findJava()
Declare progressWindow(clientVersion.s)
Declare findInstalledVersions()
Declare downloadFiles(downloadAllFiles.i)
Declare CreateDirectoryRecursive(path.s)
Declare generateProfileJson()

Declare.s parseVersionsManifest(versionType.i = 0, getClientJarUrl.i = 0, clientVersion.s = "")
Declare.s parseLibraries(clientVersion.s, prepareForDownload.i = 0)
Declare.s fileRead(pathToFile.s)
Declare.s removeSpacesFromVersionName(clientVersion.s)

programFilesDir(0) = GetEnvironmentVariable("ProgramW6432") + "\"
programFilesDir(1) = GetEnvironmentVariable("PROGRAMFILES") + "\"

; Add different java variants
javaPaths(0) = "Java"
javaPaths(1) = "BellSoft"
javaPaths(2) = "Eclipse Adoptium"


SetCurrentDirectory(workingDirectory)
OpenPreferences("vortex_launcher.conf")

downloadThreadsAmount = ReadPreferenceInteger("DownloadThreads", downloadThreadsAmountDefault)
asyncDownload = ReadPreferenceInteger("AsyncDownload", asyncDownloadDefault)

DeleteFile(tempDirectory + "vlauncher_download_list.txt")

RemoveEnvironmentVariable("_JAVA_OPTIONS")


windowWidth = 250
windowHeight = 280

; Main code------------------------------------------------------------

If OpenWindow(0, #PB_Ignore, #PB_Ignore, windowWidth, windowHeight, "Vortex Minecraft Launcher")

  gadgetsWidth = windowWidth - 10
  gadgetsHeight = 25
  gadgetsIndent = 5

  nameGadget = StringGadget(#PB_Any, gadgetsIndent, 5, gadgetsWidth, gadgetsHeight, ReadPreferenceString("Name", playerNameDefault))
  SetGadgetAttribute(nameGadget, #PB_String_MaximumLength, 16)

  ramGadget = StringGadget(#PB_Any, gadgetsIndent, 35, gadgetsWidth, gadgetsHeight, ReadPreferenceString("Ram", ramAmountDefault), #PB_String_Numeric)
  GadgetToolTip(ramGadget, "Amount (megabytes) of memory to allocate for Minecraft")
  SetGadgetAttribute(ramGadget, #PB_String_MaximumLength, 6)

  versionsGadget = ComboBoxGadget(#PB_Any, gadgetsIndent, 65, gadgetsWidth, gadgetsHeight)
  javaListGadget = ComboBoxGadget(#PB_Any, gadgetsIndent, 95, gadgetsWidth, gadgetsHeight)

  playButton = ButtonGadget(#PB_Any, gadgetsIndent, 130, gadgetsWidth, gadgetsHeight + 5, "PLAY")
  downloadButton = ButtonGadget(#PB_Any, gadgetsIndent, 165, gadgetsWidth, gadgetsHeight + 5, "Downloader")
  settingsButton = ButtonGadget(#PB_Any, gadgetsIndent, 200, gadgetsWidth, gadgetsHeight + 5, "Settings")
  saveMainButton = ButtonGadget(#PB_Any, gadgetsIndent, 235, 117, gadgetsHeight + 5, "Save")
  exitProgButton = ButtonGadget(#PB_Any, gadgetsIndent*2 + 117, 235, 117, gadgetsHeight + 5, "Exit")


  If LoadFont(0, "Arial", 10, #PB_Font_Bold)
    SetGadgetFont(playButton, FontID(0))
    SetGadgetFont(downloadButton, FontID(0))
  EndIf

  launcherAuthorGadget = TextGadget(#PB_Any, 2, windowHeight - 10, 100, 20, "by " + launcherDeveloper)
  launcherVersionGadget = TextGadget(#PB_Any, windowWidth - 34, windowHeight - 10, 50, 20, "v" + launcherVersion)
  If LoadFont(1, "Arial", 7)
    font = FontID(1) : SetGadgetFont(launcherAuthorGadget, font) : SetGadgetFont(launcherVersionGadget, font)
  EndIf

  findInstalledVersions()
  findJava()

  Repeat
    Event = WaitWindowEvent()

    If Event = #PB_Event_Gadget
      Select EventGadget()   
; PLAY Button 
        Case playButton
          ramAmount = GetGadgetText(ramGadget)
          clientVersion = GetGadgetText(versionsGadget)
          playerName = GetGadgetText(nameGadget)
          javaBinaryPath = GetGadgetText(javaListGadget)
          javaBinaryPathToSave = GetGadgetText(javaListGadget)
          downloadMissingLibraries = ReadPreferenceInteger("DownloadMissingLibs", downloadMissingLibrariesDefault)
          librariesString = ""
          clientArguments = ""
          jvmArguments = ""
          logConfArgument = ""

          If FindString(clientVersion, " ")
            clientVersion = removeSpacesFromVersionName(clientVersion)
          EndIf

          If forceDownloadMissingLibraries
            downloadMissingLibraries = 1
          EndIf

          If FindString(playerName, " ")
            playerName = ReplaceString(playerName, " ", "")
          EndIf

          If ramAmount And Len(playerName) >= 3
            If ReadPreferenceInteger("UseCustomJava", useCustomJavaDefault)
              javaBinaryPath = ReadPreferenceString("JavaPath", javaBinaryPathDefault)
            ElseIf Right(javaBinaryPath, 5) = "(x32)"
              FindMapElement(javaBinMap(), javaBinaryPath)
              javaBinaryPath = programFilesDir(1) + javaPaths(javaBinMap()) + "\" + RemoveString(javaBinaryPath, " (x32)") + "\bin\javaw.exe"
            Else
              FindMapElement(javaBinMap(), javaBinaryPath)
              javaBinaryPath = programFilesDir(0) + javaPaths(javaBinMap()) + "\" + javaBinaryPath + "\bin\javaw.exe"
            EndIf

            If Val(ramAmount) < 512
              ramAmount = "512"

              MessageRequester("Warning", "You allocated too low amount of memory!" + #CRLF$ + #CRLF$ + "Allocated memory set to 512 MB to prevent crashes.")
            EndIf
            

            If Val(ramAmount) > maxFreeMemory
              ramAmount = Str(maxFreeMemory)

              MessageRequester("Warning", "You allocated too much amount of memory!" + #CRLF$ + #CRLF$ + "Allocated memory set to maximum for your system to prevent crashes.")
            EndIf 

            WritePreferenceString("Name", playerName)
            WritePreferenceString("Ram", ramAmount)
            WritePreferenceString("ChosenVer", clientVersion)
            If FindString(javaBinaryPathToSave, "Java not found") = 0 And FindString(javaBinaryPathToSave, "Custom Java enabled in Settings") = 0            
              WritePreferenceString("javaBin", javaBinaryPathToSave) 
            EndIf

            If RunProgram(javaBinaryPath, "-version", workingDirectory)
              jsonFile = ParseJSON(#PB_Any, fileRead("versions\" + clientVersion + "\" + clientVersion + ".json"))

              If jsonFile
                clientJarFile = "versions\" + clientVersion + "\" + clientVersion + ".jar"
                nativesPath = "versions\" + clientVersion + "\natives"

                jsonObject = JSONValue(jsonFile)

                jsonJarMember = GetJSONMember(jsonObject, "jar")
                jsonInheritsFromMember = GetJSONMember(jsonObject, "inheritsFrom")

                If jsonInheritsFromMember Or jsonJarMember
                  If jsonInheritsFromMember
                    inheritsClientJar = GetJSONString(jsonInheritsFromMember)
                  Else
                    inheritsClientJar = GetJSONString(jsonJarMember)
                  EndIf

                  If FileSize(clientJarFile) < 1 And FileSize("versions\" + inheritsClientJar + "\" + inheritsClientJar + ".jar") > 0
                    CopyFile("versions\" + inheritsClientJar + "\" + inheritsClientJar + ".jar", clientJarFile)
                  EndIf

                  nativesPath = "versions\" + inheritsClientJar + "\natives"
                EndIf

                releaseTimeMember = GetJSONMember(jsonObject, "releaseTime")

                If releaseTimeMember
                  releaseTime = Val(StringField(GetJSONString(releaseTimeMember), 1, "-")) * 365 + Val(StringField(GetJSONString(releaseTimeMember), 2, "-")) * 30
                EndIf

                jsonArgumentsMember = GetJSONMember(jsonObject, "minecraftArguments")
                jsonArgumentsModernMember = GetJSONMember(jsonObject, "arguments")

                If jsonArgumentsMember
                  clientArguments = GetJSONString(jsonArgumentsMember)
                ElseIf jsonArgumentsModernMember
                  jsonArgumentsArray = GetJSONMember(jsonArgumentsModernMember, "game")
                  jsonJvmArray = GetJSONMember(jsonArgumentsModernMember, "jvm")

                  For i = 0 To JSONArraySize(jsonArgumentsArray) - 1
                    jsonArrayElement = GetJSONElement(jsonArgumentsArray, i)

                    If JSONType(jsonArrayElement) = #PB_JSON_String
                      clientArguments + " " + GetJSONString(jsonArrayElement) + " "
                    EndIf
                  Next

                  If jsonJvmArray
                    For i = 0 To JSONArraySize(jsonJvmArray) - 1
                      jsonArrayElement = GetJSONElement(jsonJvmArray, i)

                      If JSONType(jsonArrayElement) = #PB_JSON_String
                        jvmArguments + " " + Chr(34) + GetJSONString(jsonArrayElement) + Chr(34) + " "
                      EndIf
                    Next
                  EndIf
                EndIf

                If jsonInheritsFromMember
                  inheritsClientJar = GetJSONString(jsonInheritsFromMember)

                  inheritsJson = ParseJSON(#PB_Any, fileRead("versions\" + inheritsClientJar + "\" + inheritsClientJar + ".json"))

                  If inheritsJson
                    inheritsJsonObject = JSONValue(inheritsJson)
                    jsonInheritsArgumentsModernMember = GetJSONMember(inheritsJsonObject, "arguments")

                    If jsonInheritsArgumentsModernMember
                      jsonArgumentsArray = GetJSONMember(jsonInheritsArgumentsModernMember, "game")
                      jsonJvmArray = GetJSONMember(jsonInheritsArgumentsModernMember, "jvm")

                      For i = 0 To JSONArraySize(jsonArgumentsArray) - 1
                        jsonArrayElement = GetJSONElement(jsonArgumentsArray, i)

                        If JSONType(jsonArrayElement) = #PB_JSON_String
                          clientArguments + " " + GetJSONString(jsonArrayElement) + " "
                        EndIf
                      Next

                      If jsonJvmArray
                        For i = 0 To JSONArraySize(jsonJvmArray) - 1
                          jsonArrayElement = GetJSONElement(jsonJvmArray, i)

                          If JSONType(jsonArrayElement) = #PB_JSON_String
                            jvmArguments + " " + Chr(34) + GetJSONString(jsonArrayElement) + Chr(34) + " "
                          EndIf
                        Next
                      EndIf
                    EndIf

                    librariesString + parseLibraries(inheritsClientJar, downloadMissingLibraries)
                    assetsIndex = GetJSONString(GetJSONMember(JSONValue(inheritsJson), "assets"))

                    releaseTimeMember = GetJSONMember(inheritsJsonObject, "releaseTime")

                    If releaseTimeMember
                      releaseTime = Val(StringField(GetJSONString(releaseTimeMember), 1, "-")) * 365 + Val(StringField(GetJSONString(releaseTimeMember), 2, "-")) * 30
                    EndIf
                  Else
                    MessageRequester("Error", inheritsClientJar + ".json file is missing!") : Break
                  EndIf
                Else
                  If GetJSONMember(jsonObject, "assets")
                    assetsIndex = GetJSONString(GetJSONMember(jsonObject, "assets"))
                  ElseIf releaseTime > 0 And releaseTime < 734925
                    assetsIndex = "pre-1.6"
                  Else
                    assetsIndex = "legacy"
                  EndIf
                EndIf

                If jsonInheritsFromMember And inheritsJson
                  loggingMember = GetJSONMember(inheritsJsonObject, "logging")
                Else
                  loggingMember = GetJSONMember(jsonObject, "logging")
                EndIf

                If loggingMember
                  loggingClientMember = GetJSONMember(loggingMember, "client")

                  If loggingClientMember
                    loggingFileMember = GetJSONMember(loggingClientMember, "file")

                    If loggingFileMember
                      logConfArgument = "-Dlog4j.configurationFile=assets\log_configs\" + GetJSONString(GetJSONMember(loggingFileMember, "id"))
                    EndIf
                  EndIf
                EndIf

                If inheritsJson
                  FreeJSON(inheritsJson)
                EndIf

                If FileSize(clientJarFile) > 0
                  librariesString = parseLibraries(clientVersion, downloadMissingLibraries) + librariesString
                  clientMainClass = GetJSONString(GetJSONMember(jsonObject, "mainClass"))

                  UseMD5Fingerprint()

                  uuid = StringFingerprint("OfflinePlayer:" + playerName, #PB_Cipher_MD5)
                  uuid = Left(uuid, 12) + LCase(Hex(Val("$" + Mid(uuid, 13, 2)) & $0f | $30)) + Mid(uuid, 15, 2) + LCase(Hex(Val("$" + Mid(uuid, 17, 2)) & $3f | $80)) + Right(uuid, 14)

                  If assetsIndex = "pre-1.6" Or assetsIndex = "legacy"
                    assetsToResources(assetsIndex)
                  EndIf

                  If downloadMissingLibraries
                    downloadFiles(0)
                  EndIf

                  If jvmArguments = ""
                    jvmArguments = Chr(34) + "-Djava.library.path=" + nativesPath + Chr(34) + " -cp " + Chr(34) + librariesString + clientJarFile + Chr(34)
                  EndIf

                  If releaseTime > 0 And releaseTime < 736780
                    customLaunchArguments = customOldLaunchArgumentsDefault
                  Else
                    customLaunchArguments = customLaunchArgumentsDefault
                  EndIf
                  
                  useOptimisedLaunch = ReadPreferenceInteger("useOptimisedLaunch", useOptimisedLaunchDefault)
                  
                  If useOptimisedLaunch And FindString(javaBinaryPath, "1.8.0") <> 0
                    customLaunchArguments = customOptimizedLaunchArgumentsDefault
                  EndIf

                  If ReadPreferenceInteger("UseCustomParameters", useCustomParamsDefault)
                    customLaunchArguments = ReadPreferenceString("LaunchArguments", customLaunchArgumentsDefault)
                  EndIf
                  
                  allocateAllRam = ReadPreferenceInteger("allocateAllRam", allocateAllRamDefault)
                  
                  If allocateAllRam
                    fullLaunchString = "-Xms" + ramAmount + "M " + "-Xmx" + ramAmount + "M " + customLaunchArguments + " -Dlog4j2.formatMsgNoLookups=true " + logConfArgument + " " + jvmArguments + " " + clientMainClass + " " + clientArguments
                  Else
                    fullLaunchString = "-Xmx" + ramAmount + "M " + customLaunchArguments + " -Dlog4j2.formatMsgNoLookups=true " + logConfArgument + " " + jvmArguments + " " + clientMainClass + " " + clientArguments
                  EndIf
                  
                  gameDir = Chr(34) + ReplaceString(workingDirectory, "\", "\\") + Chr(34)

                  
                  fullLaunchString = ReplaceString(fullLaunchString, "${auth_player_name}", playerName)
                  fullLaunchString = ReplaceString(fullLaunchString, "${version_name}", clientVersion)
                  fullLaunchString = ReplaceString(fullLaunchString, "${game_directory}", gameDir)
                  fullLaunchString = ReplaceString(fullLaunchString, "${assets_root}", "assets")
                  fullLaunchString = ReplaceString(fullLaunchString, "${auth_uuid}", uuid)
                  fullLaunchString = ReplaceString(fullLaunchString, "${auth_access_token}", "00000000000000000000000000000000")
                  fullLaunchString = ReplaceString(fullLaunchString, "${clientid}", "0000")
                  fullLaunchString = ReplaceString(fullLaunchString, "${auth_xuid}", "0000")
                  fullLaunchString = ReplaceString(fullLaunchString, "${user_properties}", "{}")
                  fullLaunchString = ReplaceString(fullLaunchString, "${user_type}", "mojang")
                  fullLaunchString = ReplaceString(fullLaunchString, "${version_type}", "release")
                  fullLaunchString = ReplaceString(fullLaunchString, "${assets_index_name}", assetsIndex)
                  fullLaunchString = ReplaceString(fullLaunchString, "${auth_session}", "00000000000000000000000000000000")
                  fullLaunchString = ReplaceString(fullLaunchString, "${game_assets}", "resources")
                  fullLaunchString = ReplaceString(fullLaunchString, "${classpath}", librariesString + clientJarFile)
                  fullLaunchString = ReplaceString(fullLaunchString, "${library_directory}", "libraries")
                  fullLaunchString = ReplaceString(fullLaunchString, "${classpath_separator}", ";")
                  fullLaunchString = ReplaceString(fullLaunchString, "${natives_directory}", nativesPath)
                  fullLaunchString = ReplaceString(fullLaunchString, Chr(34) + "-Dminecraft.launcher.brand=${launcher_name}" + Chr(34), "")
                  fullLaunchString = ReplaceString(fullLaunchString, Chr(34) + "-Dminecraft.launcher.version=${launcher_version}" + Chr(34), "")

                  RunProgram(javaBinaryPath, fullLaunchString, workingDirectory)

                  saveLaunchString = ReadPreferenceInteger("SaveLaunchString", saveLaunchStringDefault)
                  If saveLaunchString
                    DeleteFile("launch_string.txt")

                    launchStringFile = OpenFile(#PB_Any, "launch_string.txt")
                    fullLaunchString = ReplaceString(fullLaunchString, "  ", " ")
                    WriteString(launchStringFile, Chr(34) + javaBinaryPath + Chr(34) + " " + fullLaunchString)
                    CloseFile(launchStringFile)
                  EndIf

                  If Not ReadPreferenceInteger("KeepLauncherOpen", keepLauncherOpenDefault)
                    Break
                  EndIf
                Else
                  MessageRequester("Error", "Client jar file is missing!")
                EndIf

                FreeJSON(jsonFile)
              Else
                MessageRequester("Error", "Client json file is missing!")
              EndIf
            Else
              MessageRequester("Error", "Java not found! Check if Java installed." + #CRLF$ + #CRLF$ + "Or check if path to Java binary is correct.")
            EndIf
          Else
            If playerName = ""
              MessageRequester("Error", "Enter your desired name.")
            ElseIf ramAmount = ""
              MessageRequester("Error", "Enter RAM amount.")
            ElseIf Len(playerName) < 3
              MessageRequester("Error", "Name is too short! Minimum length is 3.")
            EndIf
          EndIf
; SAVE Button           
        Case saveMainButton
          ramAmount = GetGadgetText(ramGadget)
          clientVersion = GetGadgetText(versionsGadget)
          playerName = GetGadgetText(nameGadget)
          javaBinaryPath = GetGadgetText(javaListGadget)
                    
          If FindString(playerName, " ")
            playerName = ReplaceString(playerName, " ", "")
          EndIf
          
          If ramAmount And Len(playerName) >= 3
               If Val(ramAmount) < 512
                ramAmount = "512"
          
                MessageRequester("Warning", "You allocated too low amount of memory!" + #CRLF$ + #CRLF$ + "Allocated memory set to 512 MB to prevent crashes.")
              EndIf
              
          
              If Val(ramAmount) > maxFreeMemory
                ramAmount = Str(maxFreeMemory)
          
                MessageRequester("Warning", "You allocated too much amount of memory!" + #CRLF$ + #CRLF$ + "Allocated memory set to maximum for your system to prevent crashes.")
              EndIf 
          
              WritePreferenceString("Name", playerName)
              WritePreferenceString("Ram", ramAmount)
              
              If FindString(clientVersion, "Versions not found") = 0
                If FindString(clientVersion, " ")
                  clientVersion = removeSpacesFromVersionName(clientVersion)
                EndIf
              
                WritePreferenceString("ChosenVer", clientVersion)
              EndIf
              
              If FindString(javaBinaryPath, "Java not found") = 0 And FindString(javaBinaryPath, "Custom Java enabled in Settings") = 0            
                WritePreferenceString("javaBin", javaBinaryPath) 
              EndIf
          Else
            If playerName = ""
              MessageRequester("Error", "Enter your desired name.")
            ElseIf ramAmount = ""
              MessageRequester("Error", "Enter RAM amount.")
            ElseIf Len(playerName) < 3
              MessageRequester("Error", "Name is too short! Minimum length is 3.")
            EndIf
          EndIf
 ; Download Button           
        Case downloadButton
          InitNetwork()

          *FileBuffer = ReceiveHTTPMemory("https://launchermeta.mojang.com/mc/game/version_manifest.json")
          If *FileBuffer
            If OpenWindow(1, #PB_Ignore, #PB_Ignore, 200, 120, "Client Downloader")
              DisableGadget(downloadButton, 1)

              ComboBoxGadget(325, 5, 5, 190, 25)
              versionsDownloadGadget = 325
              CheckBoxGadget(110, 5, 40, 130, 20, "Show all versions")
              versionsTypeGadget = 110
              SetGadgetState(versionsTypeGadget, ReadPreferenceInteger("ShowAllVersions", versionsTypeDefault))
              CheckBoxGadget(817, 5, 60, 130, 20, "Redownload all files")
              downloadAllFilesGadget = 817
              SetGadgetState(downloadAllFilesGadget, ReadPreferenceInteger("RedownloadFiles", downloadAllFilesDefault))
              downloadVersionButton = ButtonGadget(#PB_Any, 5, 85, 190, 30, "Download")

              If IsThread(downloadThread) : DisableGadget(downloadVersionButton, 1) : EndIf

              versionsManifestString = PeekS(*FileBuffer, MemorySize(*FileBuffer), #PB_UTF8)
              FreeMemory(*FileBuffer)

              parseVersionsManifest(GetGadgetState(versionsTypeGadget))
            EndIf
          Else
            MessageRequester("Download Error", "Seems like you have no internet connection")
          EndIf
        Case versionsTypeGadget
          ClearGadgetItems(versionsDownloadGadget)
          parseVersionsManifest(GetGadgetState(versionsTypeGadget))
; Download Versions Button 
        Case downloadVersionButton
          versionToDownload = GetGadgetText(versionsDownloadGadget)

          CreateDirectoryRecursive("versions\" + versionToDownload)

          If ReceiveHTTPFile(parseVersionsManifest(GetGadgetState(versionsDownloadGadget), 1, versionToDownload), "versions\" + versionToDownload + "\" + versionToDownload + ".json")
            DeleteFile(tempDirectory + "vlauncher_download_list.txt")
            listOfFiles = OpenFile(#PB_Any, tempDirectory + "vlauncher_download_list.txt")

            jsonFile = ParseJSON(#PB_Any, fileRead("versions\" + versionToDownload + "\" + versionToDownload + ".json"))

            If jsonFile
              jsonObject = JSONValue(jsonFile)

              assetsIndex = GetJSONString(GetJSONMember(jsonObject, "assets"))

              CreateDirectoryRecursive("assets\indexes")
              ReceiveHTTPFile(GetJSONString(GetJSONMember(GetJSONMember(jsonObject, "assetIndex"), "url")), "assets\indexes\" + assetsIndex + ".json")

              loggingMember = GetJSONMember(jsonObject, "logging")

              If loggingMember
                loggingClientMember = GetJSONMember(loggingMember, "client")

                If loggingClientMember
                  loggingFileMember = GetJSONMember(loggingClientMember, "file")

                  If loggingFileMember
                    logConfId = GetJSONString(GetJSONMember(loggingFileMember, "id"))
                    logConfUrl = GetJSONString(GetJSONMember(loggingFileMember, "url"))
                    logConfSize = GetJSONInteger(GetJSONMember(loggingFileMember, "size"))

                    WriteStringN(listOfFiles, logConfUrl + "::" + "assets\log_configs\" + logConfId + "::" + logConfSize)

                    CreateDirectoryRecursive("assets\log_configs")
                  EndIf
                EndIf
              EndIf

              clientUrl = GetJSONString(GetJSONMember(GetJSONMember(GetJSONMember(jsonObject, "downloads"), "client"), "url"))
              clientSize = GetJSONInteger(GetJSONMember(GetJSONMember(GetJSONMember(jsonObject, "downloads"), "client"), "size"))

              WriteStringN(listOfFiles, clientUrl + "::" + "versions\" + versionToDownload + "\" + versionToDownload + ".jar" + "::" + clientSize)

              FreeJSON(jsonFile)
            EndIf

            jsonFile = ParseJSON(#PB_Any, fileRead("assets\indexes\" + assetsIndex + ".json"))

            If jsonFile
              jsonObject = JSONValue(jsonFile)
              jsonObjectObjects = GetJSONMember(jsonObject, "objects")

              If ExamineJSONMembers(jsonObjectObjects)
                While NextJSONMember(jsonObjectObjects)
                  fileHash = GetJSONString(GetJSONMember(GetJSONMember(jsonObjectObjects, JSONMemberKey(jsonObjectObjects)), "hash"))
                  fileSize = GetJSONInteger(GetJSONMember(GetJSONMember(jsonObjectObjects, JSONMemberKey(jsonObjectObjects)), "size"))

                  WriteStringN(listOfFiles, "https://resources.download.minecraft.net/" + Left(fileHash, 2) + "/" + fileHash + "::" + "assets\objects\" + Left(fileHash, 2) + "\" + fileHash + "::" + fileSize)
                Wend
              EndIf

              FreeJSON(jsonFile)
            EndIf

            CloseFile(listOfFiles)

            parseLibraries(versionToDownload, 1)

            DisableGadget(playButton, 1)
            progressWindow(versionToDownload)

            downloadThread = CreateThread(@downloadFiles(), GetGadgetState(downloadAllFilesGadget))
          Else
            MessageRequester("Download Error", "Seems like you have no internet connection!")
          EndIf
; Settings Button  
        Case settingsButton
          DisableGadget(settingsButton, 1)

          If OpenWindow(3, #PB_Ignore, #PB_Ignore, 345, 295, "Vortex Launcher Settings")
              argsTextGadget = TextGadget(#PB_Any, 5, 5, 80, 30, "Launch parameters:")
              argsGadget = StringGadget(#PB_Any, 75, 5, 260, 25, ReadPreferenceString("LaunchArguments", customLaunchArgumentsDefault))
              GadgetToolTip(argsGadget, "These parameters will be used to launch Minecraft")

              javaBinaryPathTextGadget = TextGadget(#PB_Any, 5, 35, 80, 30, "Custom Java path:")
              javaPathGadget = StringGadget(#PB_Any, 75, 35, 260, 25, ReadPreferenceString("JavaPath", javaBinaryPathDefault))
              GadgetToolTip(javaPathGadget, "Absolute path to Java executable")

              downloadThreadsTextGadget = TextGadget(#PB_Any, 5, 65, 80, 30, "Download threads:")
              downloadThreadsGadget = StringGadget(#PB_Any, 75, 65, 260, 25, ReadPreferenceString("DownloadThreads", Str(downloadThreadsAmountDefault)), #PB_String_Numeric)
              GadgetToolTip(downloadThreadsGadget, "Higher numbers may speedup downloads (works only with multi-threads downloads)")
              SetGadgetAttribute(downloadThreadsGadget, #PB_String_MaximumLength, 3)

              CheckBoxGadget(311, 5, 95, 300, 20, "Fast multi-thread downloads (experimental)")
              asyncDownloadGadget = 311
              SetGadgetState(asyncDownloadGadget, ReadPreferenceInteger("AsyncDownload", asyncDownloadDefault))

              downloadMissingLibrariesGadget = CheckBoxGadget(#PB_Any, 5, 115, 300, 20, "Download missing libraries on game start")
              SetGadgetState(downloadMissingLibrariesGadget, ReadPreferenceInteger("DownloadMissingLibs", downloadMissingLibrariesDefault))

              saveLaunchStringGadget = CheckBoxGadget(#PB_Any, 5, 135, 300, 20, "Save launch string to file")
              GadgetToolTip(saveLaunchStringGadget, "Full launch string will be saved to launch_string.txt file")
              SetGadgetState(saveLaunchStringGadget, ReadPreferenceInteger("SaveLaunchString", saveLaunchStringDefault))

              useCustomJavaGadget = CheckBoxGadget(#PB_Any, 5, 155, 300, 20, "Use custom Java")
              GadgetToolTip(useCustomJavaGadget, "Use custom Java instead of installed one")
              SetGadgetState(useCustomJavaGadget, ReadPreferenceInteger("UseCustomJava", useCustomJavaDefault))

              CheckBoxGadget(313, 5, 175, 300, 20, "Use custom launch parameters")
              useCustomParamsGadget = 313
              GadgetToolTip(useCustomParamsGadget, "Use custom parameters to launch Minecraft")
              SetGadgetState(useCustomParamsGadget, ReadPreferenceInteger("UseCustomParameters", useCustomParamsDefault))

              CheckBoxGadget(689, 5, 195, 300, 20, "Keep the launcher open")
              keepLauncherOpenGadget = 689
              GadgetToolTip(keepLauncherOpenGadget, "Keep the launcher open after launching the game")
              SetGadgetState(keepLauncherOpenGadget, ReadPreferenceInteger("KeepLauncherOpen", keepLauncherOpenDefault))
              
              allocateAllRamGadget = CheckBoxGadget(#PB_Any, 5, 215, 300, 20, "Allocate all RAM")
              GadgetToolTip(allocateAllRamGadget, "Set -XmS and -XmX the same")
              SetGadgetState(allocateAllRamGadget, ReadPreferenceInteger("allocateAllRam", allocateAllRamDefault))
              
              useOptimisedLaunchGadget = CheckBoxGadget(#PB_Any, 5, 235, 300, 20, "Use optimised java args for large modpacks")
              GadgetToolTip(useOptimisedLaunchGadget, "Use only for Java 8 and versions 1.16.5 and older for large modpacks")
              SetGadgetState(useOptimisedLaunchGadget, ReadPreferenceInteger("useOptimisedLaunch", useOptimisedLaunchDefault))              

              saveSettingsButton = ButtonGadget(#PB_Any, 5, 260, 165, 30, "Save")
              closeSettingsButton = ButtonGadget(#PB_Any, 175, 260, 165, 30, "Close")

              DisableGadget(downloadThreadsGadget, Bool(Not GetGadgetState(asyncDownloadGadget)))
              DisableGadget(javaPathGadget, Bool(Not GetGadgetState(useCustomJavaGadget)))
              DisableGadget(argsGadget, Bool(Not GetGadgetState(useCustomParamsGadget)))
          EndIf
        Case useCustomParamsGadget
          DisableGadget(argsGadget, Bool(Not GetGadgetState(useCustomParamsGadget)))
        Case useCustomJavaGadget
          DisableGadget(javaPathGadget, Bool(Not GetGadgetState(useCustomJavaGadget)))
        Case useOptimisedLaunchGadget
          If GetGadgetState(useOptimisedLaunchGadget)
            MessageRequester("Warning", "This option is experimental. Use only for Java 8 and versions 1.16.5 and older for large modpacks" + #CRLF$ + #CRLF$ + "It significantly increases loading time. You have been warned!")
          EndIf

          DisableGadget(downloadThreadsGadget, Bool(Not GetGadgetState(asyncDownloadGadget)))
        Case saveSettingsButton
          If GetGadgetText(downloadThreadsGadget) = "0" : SetGadgetText(downloadThreadsGadget, "5") : EndIf

          WritePreferenceInteger("DownloadMissingLibs", GetGadgetState(downloadMissingLibrariesGadget))
          WritePreferenceInteger("AsyncDownload", GetGadgetState(asyncDownloadGadget))
          WritePreferenceInteger("SaveLaunchString", GetGadgetState(saveLaunchStringGadget))
          WritePreferenceInteger("allocateAllRam", GetGadgetState(allocateAllRamGadget))
          WritePreferenceInteger("useOptimisedLaunch", GetGadgetState(useOptimisedLaunchGadget))
          WritePreferenceInteger("UseCustomJava", GetGadgetState(useCustomJavaGadget))
          WritePreferenceInteger("UseCustomParameters", GetGadgetState(useCustomParamsGadget))
          WritePreferenceInteger("KeepLauncherOpen", GetGadgetState(keepLauncherOpenGadget))

          If GetGadgetState(useCustomJavaGadget)
            WritePreferenceString("JavaPath", GetGadgetText(javaPathGadget))
          EndIf

          If GetGadgetState(asyncDownloadGadget)
            WritePreferenceString("DownloadThreads", GetGadgetText(downloadThreadsGadget))
          EndIf

          If GetGadgetState(useCustomParamsGadget)
            WritePreferenceString("LaunchArguments", GetGadgetText(argsGadget))
          EndIf
          
          findJava()

          downloadThreadsAmount = Val(GetGadgetText(downloadThreadsGadget))
          asyncDownload = GetGadgetState(asyncDownloadGadget)

        Case closeSettingsButton
          CloseWindow(3)
          DisableGadget(settingsButton, 0)
          
        Case exitProgButton
          If Not IsThread(downloadThread) 
            End
          Else
            MessageRequester("Download in progress", "Wait for download to complete!")
          EndIf
          
        Case downloadOkButton
          CloseWindow(progressWindow)

          If IsGadget(playButton) : DisableGadget(playButton, 0) : EndIf
          If IsGadget(downloadVersionButton) : DisableGadget(downloadVersionButton, 0) : EndIf
      EndSelect
    EndIf

    If Event = #PB_Event_CloseWindow
      If EventWindow() = 1
        WritePreferenceInteger("ShowAllVersions", GetGadgetState(versionsTypeGadget))
        WritePreferenceInteger("RedownloadFiles", GetGadgetState(downloadAllFilesGadget))

        CloseWindow(1)

        DisableGadget(downloadButton, 0)
      ElseIf EventWindow() = progressWindow
        If Not IsThread(downloadThread)
          CloseWindow(progressWindow)

          If IsGadget(playButton) : DisableGadget(playButton, 0) : EndIf
          If IsGadget(downloadVersionButton) : DisableGadget(downloadVersionButton, 0) : EndIf
        Else
          MessageRequester("Download in progress", "Wait for download to complete!")
        EndIf
      ElseIf EventWindow() = 3
        CloseWindow(3)

        DisableGadget(settingsButton, 0)
      EndIf
    EndIf

  Until Event = #PB_Event_CloseWindow And EventWindow() = 0 And Not IsThread(downloadThread)

  DeleteFile(tempDirectory + "vlauncher_download_list.txt")
EndIf

; END Main code------------------------------------------------------------

; Procedures------------------------------------------------------------

Procedure findInstalledVersions()
  Protected.s dirName, chosenVer = ReadPreferenceString("ChosenVer", "")
  Protected.i directory, chosenFound

  directory = ExamineDirectory(#PB_Any, "versions", "*")

  DisableGadget(playButton, 0)
  DisableGadget(versionsGadget, 0)

  If directory
    While NextDirectoryEntry(directory)
      If DirectoryEntryType(directory) = #PB_DirectoryEntry_Directory
        dirName = DirectoryEntryName(directory)

        If dirName <> ".." And dirName <> "."
          If FileSize("versions\" + dirName + "\" + dirName + ".json") > -1
            If Not chosenFound And dirName = chosenVer
              chosenFound = 1
            EndIf

            AddGadgetItem(versionsGadget, -1, dirName)
          EndIf
        EndIf
      EndIf
    Wend

    FinishDirectory(directory)

    If chosenFound
      SetGadgetText(versionsGadget, chosenVer)
    Else
      SetGadgetState(versionsGadget, 0)
    EndIf
  EndIf

  If Not CountGadgetItems(versionsGadget)
    DisableGadget(playButton, 1)
    DisableGadget(versionsGadget, 1) : AddGadgetItem(versionsGadget, 0, "Versions not found") : SetGadgetState(versionsGadget, 0)
  Else
    generateProfileJson()
  EndIf
EndProcedure

Procedure.s parseVersionsManifest(versionType.i = 0, getClientJarUrl.i = 0, clientVersion.s = "")
  Protected.i jsonFile, jsonObject, jsonVersionsArray, jsonArrayElement, i
  Protected.s url

  jsonFile = ParseJSON(#PB_Any, versionsManifestString)

  If jsonFile
    jsonObject = JSONValue(jsonFile)

    jsonVersionsArray = GetJSONMember(jsonObject, "versions")

    For i = 0 To JSONArraySize(jsonVersionsArray) - 1
      jsonArrayElement = GetJSONElement(jsonVersionsArray, i)

      If getClientJarUrl = 0 And versionType = 0 And GetJSONString(GetJSONMember(jsonArrayElement, "type")) <> "release"
        Continue
      EndIf

      If getClientJarUrl = 0
        AddGadgetItem(versionsDownloadGadget, -1, GetJSONString(GetJSONMember(jsonArrayElement, "id")))
      Else
        If GetJSONString(GetJSONMember(jsonArrayElement, "id")) = clientVersion
          url = GetJSONString(GetJSONMember(jsonArrayElement, "url"))
          FreeJSON(jsonFile)

          ProcedureReturn url
        EndIf
       EndIf
    Next

    FreeJSON(jsonFile)
  Else
    AddGadgetItem(versionsDownloadGadget, -1, "Error")
    DisableGadget(downloadVersionButton, 1)
  EndIf

  SetGadgetState(versionsDownloadGadget, 0)
EndProcedure

Procedure.s parseLibraries(clientVersion.s, prepareForDownload.i = 0)
  Protected.i jsonLibrariesArray, jsonArrayElement, jsonFile, fileSize, downloadListFile, zipFile
  Protected.i jsonArtifactsMember, jsonDownloadsMember, jsonUrlMember, jsonClassifiersMember, jsonNativesLinuxMember
  Protected.i jsonRulesMember, jsonRulesOsMember
  Protected.i i, k, met, n
  Protected.i allowLib

  Protected.s libName, libsString, packFileName, url
  Protected.s jsonRulesOsName
  Protected Dim libSplit.s(4)
  Protected Dim fileSplit.s(10)

  If prepareForDownload = 1
    downloadListFile = OpenFile(#PB_Any, tempDirectory + "vlauncher_download_list.txt")
    FileSeek(downloadListFile, Lof(downloadListFile), #PB_Relative)
  EndIf

  UseZipPacker()

  jsonFile = ParseJSON(#PB_Any, fileRead("versions\" + clientVersion + "\" + clientVersion + ".json"))

  If jsonFile
    jsonLibrariesArray = GetJSONMember(JSONValue(jsonFile), "libraries")

    For i = 0 To JSONArraySize(jsonLibrariesArray) - 1
      jsonArrayElement = GetJSONElement(jsonLibrariesArray, i)
      allowLib = 1
      jsonRulesOsName = "empty"

      jsonRulesMember = GetJSONMember(jsonArrayElement, "rules")

      If jsonRulesMember
        For k = 0 To JSONArraySize(jsonRulesMember) - 1
          jsonRulesOsMember = GetJSONMember(GetJSONElement(jsonRulesMember, k), "os")

          If jsonRulesOsMember
            jsonRulesOsName = GetJSONString(GetJSONMember(jsonRulesOsMember, "name"))
          EndIf

          If GetJSONString(GetJSONMember(GetJSONElement(jsonRulesMember, k), "action")) = "allow"
            If jsonRulesOsName <> "empty" And jsonRulesOsName <> "windows"
              allowLib = 0
            EndIf
          Else
            If jsonRulesOsName = "windows"
              allowLib = 0
            EndIf
          EndIf
        Next
      EndIf

      If allowLib
        libName = GetJSONString(GetJSONMember(jsonArrayElement, "name"))
        
        libSplit(4) = ""
        For k = 1 To 4
          libSplit(k) = StringField(libName, k, ":")
        Next

        libName = ReplaceString(libSplit(1), ".", "\") + "\" + libSplit(2) + "\" + libSplit(3) + "\" + libSplit(2) + "-" + libSplit(3)
        
        If libSplit(4)
          libName + "-" + libSplit(4)
        EndIf
        
        If prepareForDownload = 1
          jsonDownloadsMember = GetJSONMember(jsonArrayElement, "downloads")

          If jsonDownloadsMember
            jsonArtifactsMember = GetJSONMember(jsonDownloadsMember, "artifact")
            jsonClassifiersMember = GetJSONMember(jsonDownloadsMember, "classifiers")

            If jsonClassifiersMember
              jsonNativesLinuxMember = GetJSONMember(jsonClassifiersMember, "natives-windows")

              If jsonNativesLinuxMember
                url = GetJSONString(GetJSONMember(jsonNativesLinuxMember, "url"))
                fileSize = GetJSONInteger(GetJSONMember(jsonNativesLinuxMember, "size"))

                libName + "-natives-windows"
              EndIf
            ElseIf jsonArtifactsMember
              url = GetJSONString(GetJSONMember(jsonArtifactsMember, "url"))
              fileSize = GetJSONInteger(GetJSONMember(jsonArtifactsMember, "size"))
            EndIf
          Else
            jsonUrlMember = GetJSONMember(jsonArrayElement, "url")

            If jsonUrlMember
              url = GetJSONString(jsonUrlMember) + ReplaceString(libName, "\", "/") + ".jar"
            Else
              url = "https://libraries.minecraft.net/" + ReplaceString(libName, "\", "/") + ".jar"
            EndIf
          EndIf

          WriteStringN(downloadListFile, url + "::" + "libraries\" + libName + ".jar" + "::" + fileSize)
        EndIf

        If Not GetJSONMember(jsonArrayElement, "natives")
          libsString + "libraries\" + libName + ".jar;"
        Else
          If Not Right(libName, 15) = "natives-windows"
            zipFile = OpenPack(#PB_Any, "libraries\" + libName + "-natives-windows.jar")
          Else
            zipFile = OpenPack(#PB_Any, "libraries\" + libName + ".jar")
          EndIf

          If zipFile
            CreateDirectoryRecursive("versions\" + clientVersion + "\natives")

            If ExaminePack(zipFile)
              While NextPackEntry(zipFile)
                If PackEntryType(zipFile) = #PB_Packer_File
                  packFileName = PackEntryName(zipFile)

                  If FileSize("versions\" + clientVersion + "\natives\" + packFileName) < 1
                    
                    met = FindString(packFileName, "META-INF")
                    If met = 0
                      n = CountString(packFileName, "/")
                      If n = 0
                        UncompressPackFile(zipFile, "versions\" + clientVersion + "\natives\" + packFileName)
                      Else
                        For k = 1 To n + 1
                          fileSplit(k) = StringField(packFileName, k, "/")
                        Next
                        UncompressPackFile(zipFile, "versions\" + clientVersion + "\natives\" + fileSplit(n+1))
                      EndIf
                    EndIf
                    
                  EndIf
                EndIf
              Wend
            EndIf

            ClosePack(zipFile)
          EndIf
        EndIf
      EndIf
    Next
  EndIf

  FreeJSON(jsonFile)
  FreeArray(libSplit())

  If prepareForDownload = 1 : CloseFile(downloadListFile) : EndIf

  ProcedureReturn libsString
EndProcedure

Procedure downloadFiles(downloadAllFiles.i)
  Protected Dim httpArray.i(downloadThreadsAmount)
  Protected Dim strings.s(downloadThreadsAmount)
  Protected Dim retries.i(downloadThreadsAmount)

  Protected.i failedDownloads, succeededDownloads, linesTotal, lines, allowedRetries = 5
  Protected.s string
  Protected.i file, fileSize, requiredSize, i
  Protected.i currentDownloads
  Protected.i retries

  file = ReadFile(#PB_Any, tempDirectory + "vlauncher_download_list.txt")

  If file
    While Eof(file) = 0
      ReadString(file)
      lines + 1
    Wend

    linesTotal = lines

    FileSeek(file, 0)

    If IsGadget(downloadVersionButton) : DisableGadget(downloadVersionButton, 1) : EndIf
    If IsGadget(progressBar) : SetGadgetAttribute(progressBar, #PB_ProgressBar_Maximum, linesTotal) : EndIf

    InitNetwork()

    If asyncDownload
      While (Eof(file) = 0 Or currentDownloads > 0) And failedDownloads <= 5
        For i = 0 To downloadThreadsAmount
          If httpArray(i) = 0
            string = ReadString(file)

            If string
              fileSize = FileSize(StringField(string, 2, "::"))
              requiredSize = Val(StringField(string, 3, "::"))

              If (downloadAllFiles = 0 And (fileSize = -1 Or (requiredSize <> 0 And fileSize <> requiredSize))) Or downloadAllFiles = 1
                CreateDirectoryRecursive(GetPathPart(StringField(string, 2, "::")))

                httpArray(i) = ReceiveHTTPFile(StringField(string, 1, "::"), StringField(string, 2, "::"), #PB_HTTP_Asynchronous)
                strings(i) = string
                retries(i) = 0

                currentDownloads + 1
              Else
                lines - 1
              EndIf
            EndIf
          ElseIf HTTPProgress(httpArray(i)) = #PB_HTTP_Success
            currentDownloads - 1
            lines - 1

            FinishHTTP(httpArray(i))
            httpArray(i) = 0
          ElseIf HTTPProgress(httpArray(i)) = #PB_HTTP_Failed
            FinishHTTP(httpArray(i))

            If retries(i) < allowedRetries
              httpArray(i) = ReceiveHTTPFile(StringField(strings(i), 1, "::"), StringField(strings(i), 2, "::"), #PB_HTTP_Asynchronous)
              retries(i) + 1
            Else
              retries(i) = 0
              httpArray(i) = 0

              failedDownloads + 1
              currentDownloads - 1
            EndIf
          EndIf
        Next

        If IsGadget(progressBar) : SetGadgetState(progressBar, linesTotal - lines) : EndIf
        If IsGadget(filesLeft) : SetGadgetText(filesLeft, "Files remaining: " + lines): EndIf

        Delay(500)
      Wend
    Else
      While Eof(file) = 0
        string = ReadString(file)

        If string
          lines - 1

          fileSize = FileSize(StringField(string, 2, "::"))
          requiredSize = Val(StringField(string, 3, "::"))

          If (downloadAllFiles = 0 And (fileSize = -1 Or (requiredSize <> 0 And fileSize <> requiredSize))) Or downloadAllFiles = 1
            CreateDirectoryRecursive(GetPathPart(StringField(string, 2, "::")))

            If ReceiveHTTPFile(StringField(string, 1, "::"), StringField(string, 2, "::"))
              retries = 0
            Else
              If retries < allowedRetries
                retries + 1
                FileSeek(file, -1, #PB_Relative)

                Continue
              Else
                failedDownloads = 1

                Break
              EndIf
            EndIf
          EndIf
        EndIf

        If IsGadget(progressBar) : SetGadgetState(progressBar, linesTotal - lines) : EndIf
        If IsGadget(filesLeft) : SetGadgetText(filesLeft, "Files remaining: " + lines) : EndIf
      Wend
    EndIf

    If failedDownloads
      If IsGadget(filesLeft) : SetGadgetText(filesLeft, "Download failed! " + lines + " files left.") : EndIf
    Else
      If IsGadget(filesLeft) : SetGadgetText(filesLeft, "Download complete!") : EndIf
    EndIf

    If IsGadget(progressBar) : HideGadget(progressBar, 1) : EndIf
    If IsGadget(downloadOkButton) : HideGadget(downloadOkButton, 0) : EndIf

    ClearGadgetItems(versionsGadget)
    findInstalledVersions()

    CloseFile(file)
  EndIf

  FreeArray(httpArray())
  FreeArray(strings())
  DeleteFile(tempDirectory + "vlauncher_download_list.txt")
EndProcedure

Procedure progressWindow(clientVersion.s)
  progressWindow = OpenWindow(#PB_Any, #PB_Ignore, #PB_Ignore, 230, 85, "Download progress")

  If progressWindow
    downloadingClientTextGadget = TextGadget(#PB_Any, 5, 5, 220, 20, "Version: " + clientVersion)
    filesLeft = TextGadget(#PB_Any, 5, 25, 220, 20, "Files remaining: unknown")
    progressBar = ProgressBarGadget(#PB_Any, 5, 50, 220, 20, 0, 100, #PB_ProgressBar_Smooth)
    downloadOkButton = ButtonGadget(#PB_Any, 5, 50, 220, 30, "OK")

    HideGadget(downloadOkButton, 1)
  EndIf
EndProcedure

Procedure CreateDirectoryRecursive(path.s)
  Protected.s fullPath, pathElement
  Protected.i i = 1

  Repeat
    pathElement = StringField(path, i, "\")
    fullPath + pathElement + "\"

    CreateDirectory(fullPath)

    i + 1
  Until pathElement = ""
EndProcedure

Procedure generateProfileJson()
  Protected.s fileName = "launcher_profiles.json"
  Protected.i file
  Protected.i lastProfilesJsonSize = ReadPreferenceInteger("LastProfilesJsonSize", 89)
  Protected.i fileSize = FileSize(fileName)

  If fileSize <= 0
    DeleteFile(fileName)
    file = OpenFile(#PB_Any, fileName)

    If file
      WriteString(file, "{ " + Chr(34) + "profiles" + Chr(34) + ": { " + Chr(34) + "justProfile" + Chr(34) + ": { " + Chr(34) + "name" + Chr(34) + ": " + Chr(34) + "justProfile" + Chr(34) + ", ")
      WriteString(file, Chr(34) + "lastVersionId" + Chr(34) + ": " + Chr(34) + "1.18.2" + Chr(34) + " } } }" + #CRLF$)

      CloseFile(file)
    EndIf
  EndIf

  fileSize = FileSize(fileName)

  If fileSize <> lastProfilesJsonSize
    forceDownloadMissingLibraries = 1
  EndIf

  WritePreferenceInteger("LastProfilesJsonSize", fileSize)
EndProcedure

Procedure.s fileRead(pathToFile.s)
  Protected.i file
  Protected.s fileContent

  file = ReadFile(#PB_Any, pathToFile)

  If file
    Repeat
      fileContent + ReadString(file) + #CRLF$
    Until Eof(file)

    CloseFile(file)
  EndIf

  ProcedureReturn fileContent
EndProcedure

Procedure findJava()
  Protected.s dirName, javaBinaryPath, customJavaPath, javabinConfig, javaItemText
  Protected.i i, directory, numberJavaItems, k, j
  
  ClearGadgetItems(javaListGadget)
  DisableGadget(javaListGadget, 0)

  If GetGadgetText(versionsGadget) <> "Versions not found" And Not IsThread(downloadThread)
    DisableGadget(playButton, 0)
  EndIf

  If ReadPreferenceInteger("UseCustomJava", useCustomJavaDefault)
    AddGadgetItem(javaListGadget, -1, "Custom Java enabled in Settings")
    SetGadgetState(javaListGadget, 0)
    DisableGadget(javaListGadget, 1)
  Else
    For i = 0 To 1
      If programFilesDir(i) <> "\"
        
        For j = 0 To 2
          directory = ExamineDirectory(#PB_Any, programFilesDir(i) + javaPaths(j), "*")
  
          If directory
            While NextDirectoryEntry(directory) And DirectoryEntryType(directory) = #PB_DirectoryEntry_Directory
              dirName = DirectoryEntryName(directory)
  
              If dirName <> ".." And dirName <> "." And FileSize(programFilesDir(i) + javaPaths(j) + "\" + dirName + "\bin\javaw.exe") > 0
                If i
                  dirName + " (x32)"
                EndIf
                
                javaBinMap(dirName) = j
  
                AddGadgetItem(javaListGadget, -1, dirName)
                SetGadgetState(javaListGadget, 0)
              EndIf
            Wend
  
            FinishDirectory(directory)
          EndIf
        Next
      EndIf
    Next

    If Not CountGadgetItems(javaListGadget)
      AddGadgetItem(javaListGadget, -1, "Java not found")
      SetGadgetState(javaListGadget, 0)

      DisableGadget(javaListGadget, 1)
      DisableGadget(playButton, 1)
    Else
        javaBinaryPath = GetGadgetText(javaListGadget)
        javabinConfig = ReadPreferenceString("javaBin", "")
        
        If javabinConfig <> "" And FindString(javaBinaryPath, "Java not found") = 0
          numberJavaItems = CountGadgetItems(javaListGadget)
          For k = 0 To numberJavaItems - 1
            javaItemText = GetGadgetItemText(javaListGadget, k)
            If javabinConfig = javaItemText
              SetGadgetState(javaListGadget, k)
              Break
            EndIf
          Next
        EndIf
    EndIf
  EndIf
EndProcedure

Procedure assetsToResources(assetsIndex.s)
  Protected.i jsonFile, jsonObject, jsonObjectObjects, fileSize
  Protected.s fileHash, fileName

  jsonFile = ParseJSON(#PB_Any, fileRead("assets\indexes\" + assetsIndex + ".json"))

  If jsonFile
    jsonObject = JSONValue(jsonFile)
    jsonObjectObjects = GetJSONMember(jsonObject, "objects")

    If ExamineJSONMembers(jsonObjectObjects)
      While NextJSONMember(jsonObjectObjects)
        fileHash = GetJSONString(GetJSONMember(GetJSONMember(jsonObjectObjects, JSONMemberKey(jsonObjectObjects)), "hash"))
        fileSize = GetJSONInteger(GetJSONMember(GetJSONMember(jsonObjectObjects, JSONMemberKey(jsonObjectObjects)), "size"))
        fileName = JSONMemberKey(jsonObjectObjects)

        fileName = ReplaceString(fileName, "/", "\")

        If FileSize("resources\" + fileName) <> fileSize
          CreateDirectoryRecursive("resources\" + GetPathPart(fileName))

          CopyFile("assets\objects\" + Left(fileHash, 2) + "\" + fileHash, "resources\" + fileName)
        EndIf
      Wend
    EndIf

    FreeJSON(jsonFile)
  EndIf
EndProcedure

Procedure.s removeSpacesFromVersionName(clientVersion.s)
  Protected.s newVersionName = ReplaceString(clientVersion, " ", "-")

  RenameFile("versions\" + clientVersion + "\" + clientVersion + ".jar", "versions\" + clientVersion + "\" + newVersionName + ".jar")
  RenameFile("versions\" + clientVersion + "\" + clientVersion + ".json", "versions\" + clientVersion + "\" + newVersionName + ".json")
  RenameFile("versions\" + clientVersion, "versions\" + newVersionName)

  ProcedureReturn newVersionName
EndProcedure

ReleaseMutex_(Mutex)
End