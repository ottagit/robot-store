*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF


*** Variables ***
${url}=  https://robotsparebinindustries.com/#/robot-order
${GLOBAL_RETRY_AMT}=  3x
${GLOBAL_RETRY_INTVL}=  0.5s
${pdf}
${robot_img}

*** Keywords ***
Open the robot order website
    Open Available Browser  ${url}

*** Keywords ***
Get orders
    Download    https://robotsparebinindustries.com/orders.csv  overwrite=True
    ${orderTable}=  Read table from CSV    orders.csv
    [Return]    ${orderTable}

*** Keywords ***
Close the annoying modal
    Click Button When Visible  class:btn-dark

*** Keywords ***
Fill the form
    [Arguments]  ${order}
    Select From List By Value    id:head  ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text  xpath://*[starts-with(@id, "1638")]  ${order}[Legs]
    Input Text    id:address    ${order}[Address]

*** Keywords ***
Preview the bot
    Click Button  Preview

*** Keywords ***
Submit the order
    Click Button    Order

*** Keywords ***
Store order HTML receipt as PDF
    [Arguments]  ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${html_receipt}=  Get Element Attribute  id:receipt  outerHTML
    ${pdf}=  Html To Pdf    ${html_receipt}    ${CURDIR}${/}output${/}receipts${/}order_receipt.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]  ${order_number}
    Wait Until Element Is Visible    css:div#robot-preview-image
    ${robot_img}=  Screenshot  css:div#robot-preview-image  ${CURDIR}${/}output${/}images${/}robot_preview.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${files}  ${target_doc}
    Open PDF  ${pdf}
    ${image_files} =    Create List    ${files}:align=center
    Add Files To Pdf  ${image_files}  ${pdf}  append=True
    Close Pdf  ${pdf}

*** Tasks ***
Order robots from the RobotSPareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders}=  Get orders

    FOR  ${order}  IN  @{orders}
        Fill the form  ${order}
        Preview the bot
        Wait Until Keyword Succeeds
        ...     ${GLOBAL_RETRY_AMT}
        ...     ${GLOBAL_RETRY_INTVL}
        ...     Submit the order
        ${pdf_receipt}=  Store order HTML receipt as PDF  ${order}[Order number]
        ${screenshot}=  Take a screenshot of the robot  ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file  ${screenshot}  ${pdf_receipt}
    END


