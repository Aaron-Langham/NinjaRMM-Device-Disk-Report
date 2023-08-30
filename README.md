# NinjaRMM-Device-Disk-Report
Script to generate a report on all the devices in a given group in NinjaRMM

Takes a Group ID from Ninja RMM and uses the API to collect the disk data from every machine in the group and formats it into HTML and sends it as an email.

This Script can be run on anything that has access to the internet and can run PowerShell, e.g. Desktop, Server, Linux, Docker Container, Azure FunctionApp, etc

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

Getting SMTP settings:
  This will vary depending on your mail server/SMTP provider but you'll need to fill in:
  Username
  Password
  To Address
  From Address
  SMTP server address
  SMPT port
