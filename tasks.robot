# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.HTTP
Library           RPA.FileSystem
Library           RPA.Browser   
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

# -
*** Keywords ***
Get User URL
    Add text input    url    label=URL ( https://robotsparebinindustries.com/orders.csv )
    ${response}=    Run dialog
    [Return]    ${response.url}

*** Variables ***
${PDF_Directory} =     ${CURDIR}${/}receipts

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt}=        Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}order_nro_${Order number}.pdf
    [Return]    ${OUTPUT_DIR}${/}order_nro_${Order number}.pdf

*** Keywords ***
Get orders
    Create Directory     ${PDF_Directory}
    ${url}=     Get User URL
    Download    ${url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders} 


*** Keywords ***
Submit the order
   Click Button When Visible    //button[@id="order"]
    Wait Until Element Is Visible   id:receipt

*** Keywords ***
Go to order another robot
    Click Button    //button[@id="order-another"]

*** Keywords ***
Log out and close the browser
   Close Browser
   sleep  1s

*** Keywords ***
Preview the Robot
    Click Element    //button[@id="preview"]

*** Keywords ***
Close the annoying modal
    Click Element    //button[@class="btn btn-warning"]

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    xpath=(//input[@name="body"])[${row}[Body]]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    //input[@name="address"]    ${row}[Address]


*** Keywords ***
Open the robot order website
    #${website}=    Get Secret    website
    
    #Open Available Browser     ${website}[path]
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders

    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Wait Until Keyword Succeeds    1 min    1 sec   Submit the order  
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log out and close the browser


*** Keywords ***
Create a ZIP file of the receipts
   ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}recepts.zip
   Archive Folder With Zip     ${PDF_Directory}     ${zip_file_name}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${name_pdf}=    Get File Name    ${pdf}
    Add Watermark Image To PDF   ${screenshot}    ${PDF_Directory}${/}${name_pdf}   ${pdf}    
    
    Close Pdf    ${pdf}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${Order number}
    Wait Until Element Is Visible    id:robot-preview-image    
    Capture Element Screenshot    id:robot-preview-image     ${OUTPUT_DIR}${/}order_im_${Order number}.png
    [Return]    ${OUTPUT_DIR}${/}order_im_${Order number}.png
