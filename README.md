# NinjaRMM-Device-Disk-Report
Script to generate a report on all the devices in a given group in NinjaRMM

Takes a Group ID from Ninja RMM and uses the API to collect the disk data from every machine in the group and formats it into HTML and sends it as an email.

This Script can be run on anything that has access to the internet and can run PowerShell, e.g. Desktop, Server, Linux, Docker Container, Azure FunctionApp, etc

V4: Sends email via SMTP
V5: Sends email via Microsoft 365 (only supports email from that)
V6: Same as V5 but now with threading so now it's 'up to' 6x faster (statistics gathered in my grand total of 1 test)


Getting API Key:
  Go to NinjaRMM/NinjaOne portal > Administration > Apps > API > Client App IDs
  Add
  Application Platform: Web
  Name: Something appropriate
  Redirect URIs: http://localhost/
  Scopes: Monitoring
  Allowed Grant Types: Authorization Code, Clent Credentials, Refresh Token

  Make note of the ClientSecret and ClientID
  Set the variables in the script to those values

Getting Group ID:
  Go to NinjaRMM/NinjaOne portal > Administration > Devices > Groups
  Find the group you want to get the info from and click on it
  The ID will be the number at the end of that page's URL, e.g. https://xyz.rmmservice.eu/#/group/55 in this case it's 55
  Set the variable in the script to that value

V4.5:
  Getting SMTP settings:
    This will vary depending on your mail server/SMTP provider but you'll need to fill in:
    Username
    Password
    To Address
    From Address
    SMTP server address
    SMPT port

V5+:
  Go to the Azure portal - App registrations > New Registration.
    Name: Microsoft Graph PowerShell – Mail
    For Supported account types, select Accounts in this organization directory. 
    For Redirect URI: 
      Select Public client/native from the drop down
      URI value: http://localhost
    Select Register.
  Go to Enterprise applications and select the application you just created.
    Under Manage, select Properties, and set Assignment required? to Yes.
    Select Save.
    Under Manage, select Users and groups.
    Select Add user/group and add the users and groups permitted to use this application.
    Once you've added all the users and groups, select Assign.
  Go to App registrations and select the application you just created.
    Under Manage, select API permissions, Add a permission
      Microsoft Graph > Application Permissions > Mail 
      check ‘Mail.ReadWrite’,’Mail.Send’, Add Permissions
      Click Grant admin Consent for xxx
    Go to Overview and Make note of Application (client) ID and Directory (tenant) ID
    Go to Certificates & Secrets > Client Secrets
      New client secret 
      Give appropriate name and expiry time
      Make note of the Value
    Go to Users, Find the user you want to send from and make a note of the User ID

  If you're running this in an Azure Function app:
    Go to the App Files Tab
    Edit the host.json file:
      "managedDependency": {
      "Enabled": true
    And the requirements.psd1 file:
      @{
        'Microsoft.Graph.Authentication' = '2.\*'
        'Microsoft.Graph.Mail' = '2.\*'
        'Microsoft.Graph.Users.Actions' = '2.\*'
      }
    It will through an error saying there isn't enough space to install the module, but it still works. (for me at least)






















