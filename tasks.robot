*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
#Library           RPA.Excel.Files
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           String
Library           RPA.Archive
Library           RPA.Robocloud.Secrets
Library           RPA.Dialogs

*** Keywords ***
Open The Robot Order Website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    #Open Available Browser    https://robotsparebinindustries.com/

*** Keywords ***
Download The CSV file & Get orders
    [Arguments]     ${csvFileLink}
    Download    ${csvFileLink}    overwrite=True
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    #Open Workbook    orders.csv
    ${Get orders}=    Read Table From Csv   orders.csv  header=True
    Wait Until Page Contains Element    id:address
    [Return]    ${Get Orders}

*** Keywords ***
Ask user for the CSV File link
    Create Form     Please provide Orders file link
    Add Text Input    Orders File Link    csvFileLink
    &{response}    Request Response
    #Log     ${response}
    [Return]    ${response["csvFileLink"]}   

*** Keywords ***
Preview the robot
    Wait Until Page Contains Element    id:preview
    Click Button    preview

*** Keywords ***
Submit the order
    Wait Until Page Contains Element    id:robot-preview-image
    #Wait Until Keyword Succeeds   3    10    alert alert-danger
    Click Button    order
    Sleep   3s
    Mute Run On Failure     Wait Until Element Is Visible    id:receipt
    Run Keyword And Ignore Error    Wait Until Element Is Visible    id:receipt

*** Keywords ***
Fill The Form Using The Data From The CSV File
    [Arguments]   ${row}
    Input Text    address    ${row}[Address]
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    ${legsElement}=   Get Element Attribute     class:form-control  outerHTML
    ${legsElemId} =   Fetch From Left   ${legsElement}      " name
    ${legsElemId} =   Fetch From Right   ${legsElemId}      id="
    Input Text    ${legsElemId}   ${row}[Legs]
    #Log   ${legsElement}
    #Log   ${legsElemId}}
    #Log     ${legsElement["id"]} 
    Input Text    address   ${row}[Address]


*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK

*** Keywords ***
Check if receipt is generated
    Wait Until Element Is Visible    id:receipt

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${row}
    ${check}=   Is Element Visible     id:receipt
    IF   ${check} == True
            ${order_receipt}=    Get Element Attribute    id:receipt       outerHTML
            Html To Pdf    ${order_receipt}    ${CURDIR}${/}output${/}${row}.pdf
            #[Return]    ${CURDIR}${/}output${/}${row}.pdf
    ELSE
            Sleep   4s
            Click Button    order
            Sleep   4s
            ${order_receipt}=    Get Element Attribute    id:receipt       outerHTML
            Html To Pdf    ${order_receipt}    ${CURDIR}${/}output${/}${row}.pdf
            #[Return]    ${CURDIR}${/}output${/}${row}.pdf
    END
    #Wait Until Element Is Visible    id:receipt
    #${order_receipt}=    Get Element Attribute    id:receipt       outerHTML
    #Html To Pdf    ${order_receipt}    ${CURDIR}${/}output${/}${row}.pdf
    [Return]    ${CURDIR}${/}output${/}${row}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot   id:robot-preview-image     ${CURDIR}${/}output${/}${row}.png
    [Return]    ${CURDIR}${/}output${/}${row}.png
    #${robot_image}=    Screenshot   id:robot-preview-image
    #Html To Pdf    ${robot_image}   ${CURDIR}${/}output${/}order_data.pdf
    #[Return]    ${CURDIR}${/}output${/}${row}.pdf

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf   ${pdf}
    Add Watermark Image To Pdf    ${screenshot}     ${pdf}
    Close Pdf   ${pdf}

*** Keywords ***
Go to order another robot
    Wait Until Page Contains Element    id:order-another
    Click Button    Order another robot

*** Keywords ***
Log Out And Close The Browser
    #Click Button    Log out
    Close Browser

*** Keywords ***
Create a ZIP file of the receipts
   Archive Folder With ZIP   ${CURDIR}${/}output  ${CURDIR}${/}output${/}receiptPDFs.zip   recursive=True  include=*.pdf  exclude=/.png
   #@{files}                  List Archive             receiptPDFs.zip
   #FOR  ${file}  IN  ${files}
   #   Log  ${file}
   #END
   #Add To Archive            .${/}..${/}missing.robot  receiptPDFs.zip
   #&{info}                   Get Archive Info    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secret}=    Get Secret    credentials
    Log    ${secret}[username]
    Log    ${secret}[password]
    ${csvFileLink}=     Ask user for the CSV File link
    Open The Robot Order Website    
    ${orders}=    Download The CSV file & Get orders    ${csvFileLink}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill The Form Using The Data From The CSV File   ${row}
        Preview the robot
        #Submit the order
        Wait Until Keyword Succeeds    5x    3s    Submit the order
        #Wait Until Keyword Succeeds    3x    1s    Check if receipt is generated
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Sleep	2s
        Go to order another robot
        Exit For Loop If    ${row}[Order number] == 2
    END
    Create a ZIP file of the receipts
    Log  Done.
    [Teardown]    Log Out And Close The Browser



