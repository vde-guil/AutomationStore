*** Settings ***
Library     OperatingSystem
Library     SeleniumLibrary
Library     JSONLibrary
Library     RequestsLibrary
Library     %{PROJECT_FOLDER}/libs/Common.py
Resource    %{PROJECT_FOLDER}/tests/data-env/env.resource


*** Variables ***
# chrome | chromemobileemulation | edge | firefox
${BROWSER}              chrome
# no | yes (case insensitive, default no if <> yes)
${BROWSER_HEADLESS}     NO
# OK | KO
${ENV}                  OK
# fr | en
${LANG}                 fr
# ----------------------------------------------------------------------
${COMPTE_ADMIN}         ${EMPTY}
${TRANSLATE}            ${EMPTY}


*** Keywords ***
Suite Setup
    Log To Console    ${EMPTY}
    Log To Console    ================================================================== SUITE SETUP
    Log To Console    CURDIR____________\t${CURDIR}
    Log To Console    EXECDIR___________\t${EXECDIR}
    Log To Console    OUTPUT DIR________\t${OUTPUT DIR}
    Log To Console    ENV_______________\t${ENV}
    Log To Console    BROWSER___________\t${BROWSER}
    Log To Console    LANG______________\t${LANG}
    Log To Console    ${EMPTY}
    RequestsLibrary.GET    ${URL_OPENCRUISE_${ENV}}/api/helper/villes    expected_status=200
    ${compte_admin}    Create Dictionary
    ...    username=%{OPENCRUISE_ADMIN_USER}    # créer les variables d'environnement
    ...    password=%{OPENCRUISE_ADMIN_PWD}
    ...    nom=ADMIN
    ...    prenom=TEST
    Set Global Variable    ${COMPTE_ADMIN}    ${compte_admin}
    # chargement de la traduction par défaut en FR
    ${translate}    JSONLibrary.Load Json From File    %{PROJECT_FOLDER}/tests/data-env/lang-fr.json    encoding=utf-8
    # chargement de la traduction par dynamique en fonction du changement de langue
    # ${translate}    JSONLibrary.Load Json From File    %{PROJECT_FOLDER}/tests/data-env/lang-${LANG}.json    encoding=utf-8
    Set Global Variable    ${TRANSLATE}    ${translate}

Test Setup
    Log To Console    ${EMPTY}
    Log To Console    ================================================================== TEST SETUP
    Register Keyword To Run On Failure    NONE
    Run Keyword    Open${BROWSER}
    Set Browser Implicit Wait    5
    Maximize Browser Window

# Openchrome
#    ${options}    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
#    Call Method    ${options}    add_argument    incognito
#    ${excludeSwitches}    Create List    enable-automation    enable-logging    disable-popup-blocking
#    Call Method    ${options}    add_experimental_option    excludeSwitches    ${excludeSwitches}
#    IF    '''${BROWSER_HEADLESS}'''.casefold() == 'YES'
#    Call Method    ${options}    add_argument    headless
#    END
#    Open Browser
#    ...    url=${URL_OPENCRUISE_${ENV}}
#    ...    browser=chrome
#    ...    options=${options}

# Openchromemobileemulation
#    ${options}    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
#    Call Method    ${options}    add_argument    incognito
#    ${excludeSwitches}    Create List    enable-automation    enable-logging    disable-popup-blocking
#    Call Method    ${options}    add_experimental_option    excludeSwitches    ${excludeSwitches}
#    IF    '''${BROWSER_HEADLESS}'''.casefold() == 'YES'
#    Call Method    ${options}    add_argument    headless
#    END
#    Open Browser
#    ...    url=${URL_OPENCRUISE_${ENV}}
#    ...    browser=chrome
#    ...    options=${options}

Openchrome
    [Documentation]    Open chrome
    ${options}    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys, selenium.webdriver
    ${options}    ChromiumOptions    ${options}
    SeleniumLibrary.Open Browser
    ...    url=${URL}
    ...    browser=chrome
    ...    options=${options}

ChromiumOptions
    [Documentation]    Option de Chromium
    [Arguments]    ${options}
    Call Method    ${options}    add_argument    incognito
    Call Method    ${options}    add_argument    ignore-certificate-errors
    ${excludeSwitches}    Create List    enable-automation    enable-logging    disable-popup-blocking
    Call Method    ${options}    add_experimental_option    excludeSwitches    ${excludeSwitches}
    IF    '''${BROWSER_HEADLESS}'''.upper() == 'YES'
        Call Method    ${options}    add_argument    headless
    END
    ${prefs}    Create Dictionary
    ...    profile.default_content_settings.popups=${0}
    ...    download.default_directory=${OUTPUT_DIR}
    ...    download.prompt_for_download=${False}
    ...    download.directory_upgrade=${True}
    ...    safebrowsing.enabled=${True}
    ...    plugins.always_open_pdf_externally=${True}
    ...    profile.password_manager_enabled=${False}
    Call Method    ${options}    add_experimental_option    prefs    ${prefs}
    RETURN    ${options}

Openedge
    ${options}    Evaluate    sys.modules['selenium.webdriver'].EdgeOptions()    sys, selenium.webdriver
    Call Method    ${options}    add_argument    incognito
    IF    '''${BROWSER_HEADLESS}'''.casefold() == 'YES'
        Call Method    ${options}    add_argument    headless
    END
    Open Browser
    ...    url=${URL_OPENCRUISE_${ENV}}
    ...    browser=edge
    ...    options=${options}

Openfirefox
    [Documentation]    Open firefox
    ...    faire about:config dans firefox

    ${options}    Evaluate    sys.modules['selenium.webdriver'].FirefoxOptions()    sys, selenium.webdriver
    IF    '''${BROWSER_HEADLESS}'''.upper() == 'YES'
        OperatingSystem.Set Environment Variable    MOZ_HEADLESS    ${1}
    END

    Call Method    ${options}    set_preference    browser.download.folderList    ${2}
    Call Method    ${options}    set_preference    browser.download.manager.showWhenStarting    ${False}
    Call Method    ${options}    set_preference    browser.download.manager.focusWhenStarting    ${False}
    Call Method    ${options}    set_preference    browser.download.dir    ${OUTPUT_DIR}
    Call Method    ${options}    set_preference    browser.helperApps.alwaysAsk.force    ${False}
    Call Method    ${options}    set_preference    browser.download.manager.alertOnEXEOpen    ${False}
    Call Method    ${options}    set_preference    browser.download.manager.closeWhenDone    ${True}
    Call Method    ${options}    set_preference    browser.download.manager.showAlertOnComplete    ${False}
    Call Method    ${options}    set_preference    browser.download.manager.useWindow    ${False}
    Call Method    ${options}    set_preference    browser.helperApps.neverAsk.saveToDisk    application/octet-stream
    Call Method    ${options}    set_preference    pdfjs.disabled    ${True}
    SeleniumLibrary.Open Browser
    ...    url=${URL}
    ...    browser=firefox
    ...    options=${options}

Capture Step ScreenShot
    [Documentation]    Capture avec règle de nommage du fichier
    ...    Le step permet d'identifier l'étape et de faire plusieurs captures par test
    [Arguments]    ${step}
    ${filename}    Common.Clean String Filename    ${TEST NAME}_${step}
    SeleniumLibrary.Capture Page Screenshot    ${OUTPUT DIR}${/}${filename}.png
    IF    '''${step}''' == 'FAIL'
        ${html}    SeleniumLibrary.Get Source
        OperatingSystem.Create File    path=${OUTPUT DIR}${/}${filename}.html    content=${html}    encoding=UTF-8
    END

Capture Step Element ScreenShot
    [Documentation]    Capture avec règle de nommage du fichier
    ...    Le step permet d'identifier l'étape et de faire plusieurs captures par test
    [Arguments]    ${step}    ${locator}
    ${filename}    Common.Clean String Filename    ${TEST NAME}_${step}
    SeleniumLibrary.Capture Element Screenshot    ${locator}    ${OUTPUT DIR}${/}${filename}.png

Test Teardown
    Capture Step ScreenShot    ${TEST_STATUS}
    Close All Browsers

Suite Teardown
    Log To Console    ${EMPTY}
