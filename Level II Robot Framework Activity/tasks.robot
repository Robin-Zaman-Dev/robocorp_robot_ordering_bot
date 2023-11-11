*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Excel.Application
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Read CSV file and submit orders
    Zip the pdf files
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=${True}

Read CSV file and submit orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    FOR    ${orders}    IN    @{orders}
        Create order for each line item of CSV and store it as PDF    ${orders}
    END

Create order for each line item of CSV and store it as PDF
    [Arguments]    ${orders}
    Click Button    OK
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Wait Until Element Is Visible    preview
    Wait Until Keyword Succeeds    10x    4s    Click Button    preview
    TRY
        Click order button to preview the receipt
        ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
        ${robot_image}=    Screenshot
        ...    id:robot-preview-image
        ...    ${CURDIR}${/}screenshots${/}${orders}[Order number].png
        Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}${orders}[Order number].pdf
        Open Pdf    ${OUTPUT_DIR}${/}${orders}[Order number].pdf
        ${new_robot_image}=    Create List    ${robot_image}:x=0,y=0
        Add Files To Pdf    ${new_robot_image}    ${OUTPUT_DIR}${/}${orders}[Order number].pdf    ${True}
        Close Pdf    ${OUTPUT_DIR}${/}${orders}[Order number].pdf
        Wait Until Keyword Succeeds    10x    10s    Click Button    order-another
    EXCEPT    Failed!
        Log    BOT failed...
    END

Click order button to preview the receipt
    Wait Until Element Is Visible    order
    Wait Until Keyword Succeeds    15x    10s    Click Button    order
    Run Keyword And Continue On Failure    Click order button to preview the receipt

Zip the pdf files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}all_receipts.zip
    Archive Folder With Zip    ${CURDIR}${/}output    ${zip_file_name}

Minimal task
    Log    Done.
